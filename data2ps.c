/* Takes output of analyze_function.sh as parameters and produces
   PostScript for a single function. */
#include <unistd.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

#define MAXSIZE 1000
#define LINE_LENGTH 5
#define MAX_VARIANCE 6
#define FORK_MINVAR 20
#define FORK_MAXVAR 120

#define DEG2RAD(d) ((d)/180.0 * M_PI)

#define DIST(x,y) sqrt((double)(x) * (x) + (double)(y) * (y))

struct coord
{
	float x;
	float y;
};

struct bounding_box
{
	struct coord min, max;
};

struct context
{
	struct coord last_end;
	struct bounding_box bound;
	/* buffer containing output, NUL terminated. */
	char *buffer;
	/* size of malloced buffer */
	unsigned int buffer_size;
};

static void update_boundingbox(struct bounding_box *bound, struct coord c)
{
	if (c.x < bound->min.x) bound->min.x = c.x;
	if (c.y < bound->min.y) bound->min.y = c.y;
	if (c.x > bound->max.x) bound->max.x = c.x;
	if (c.y > bound->max.y) bound->max.y = c.y;
}

static void combine_boundingboxes(struct bounding_box *bound,
				  struct bounding_box oldbound)
{
	/* This is overkill, but easy */
	update_boundingbox(bound, oldbound.min);
	update_boundingbox(bound, oldbound.max);
}

static void dump(struct context *context)
{
	fputs(context->buffer, stdout);
}

static void print(struct context *context, char *fmt, ...)
{
	char *p;
	va_list ap;
	size_t size = strlen(context->buffer);

	p = context->buffer + size;
	va_start(ap, fmt);

	while (vsnprintf(p, context->buffer_size - size, fmt, ap) 
	       > context->buffer_size - size - 1) {
		context->buffer_size *= 2;
		context->buffer = realloc(context->buffer,
					  context->buffer_size);
		p = context->buffer + size;
	}
}

static struct coord draw_line(unsigned len,
			      int complexity,
			      float angle,
			      struct coord from,
			      struct context *context)
{
	struct coord to;

	/* Do we need to move? */
	if (from.x != context->last_end.x || from.y != context->last_end.y) {
		print(context, "%.2f %.2f moveto\n", from.x, from.y);
		update_boundingbox(&context->bound, from);
	}

	to.x = cos(DEG2RAD(angle))*len + from.x;
	to.y = sin(DEG2RAD(angle))*len + from.y;

	/* Draw line */
	print(context, "%.2f %.2f lineto\n", to.x, to.y);

	/* Update context */
	context->last_end.x = to.x;
	context->last_end.y = to.y;

	/* Draw hair */
	if (complexity > random() % 50) {
		int left = random()%2;
		float hairangle = angle + (left ? 60 : -60);

		print(context, "%% hair!\n");
		draw_line(3, 0, hairangle, to, context);
	}

	/* Update bounding box */
	update_boundingbox(&context->bound, to);
	return to;
}

static unsigned int iterate(struct context *c,
			    struct coord *here,
			    float *angle,
			    unsigned int depth,
			    int do_loop);

static unsigned loop(struct context *c,
		     struct coord *here,
		     float *angle,
		     int do_loop)
{
	/* Start new bounding box: we want to draw
	   circle around it */
	struct bounding_box old_bound;
	unsigned int advancedness;
	float radius;

	old_bound = c->bound;
	c->bound.min.x = c->bound.max.x = here->x;
	c->bound.min.y = c->bound.max.y = here->y;

	advancedness = iterate(c, here, angle, 0, do_loop);

	/* Draw a circle approx. around range covered. */
	radius = DIST(c->bound.max.x - c->bound.min.x,
		      c->bound.max.y - c->bound.min.y)/2.3;

	print(c, "gsave\n");
	print(c, "newpath\n");
	print(c, "%.2f %.2f %.2f 0 360 arc\n",
	      (c->bound.max.x + c->bound.min.x)/2,
	      (c->bound.max.y + c->bound.min.y)/2,
	      radius);
	print(c, "stroke\n");
	print(c, "grestore\n");

	/* Update bounding box */
	combine_boundingboxes(&c->bound, old_bound);
	return advancedness;
}

static unsigned int iterate(struct context *c,
			    struct coord *here,
			    float *angle,
			    unsigned int depth,
			    int do_loop)
{
	char arg[20];
	unsigned int advancedness = 0;

	while (fgets(arg, sizeof(arg), stdin)) {
		if (strcmp(arg, "f(\n") == 0) {
			/* FIXME: Control angle by weight of different branches */
			/* Branch */
			unsigned int fork_margin
				= random()%(FORK_MAXVAR/2) + FORK_MINVAR/2;
			float newangle;
			struct coord new = *here;

			print(c, "%% If starts here\n");
			newangle = *angle + fork_margin;
			while (newangle > 360) newangle -= 360;
			advancedness += iterate(c, &new, &newangle, 0, 0);
			*angle -= fork_margin;
			while (newangle < 0) newangle += 360;
			print(c, "%% If ends here\n");
		} else if (strcmp(arg, "d(\n") == 0) {
			print(c, "%% do loop start\n");
			advancedness += loop(c, here, angle, 1);
			print(c, "%% do loop end\n");
		} else if (strcmp(arg, "f(\n") == 0) {
			print(c, "%% for loop start\n");
			advancedness += loop(c, here, angle, 0);
			print(c, "%% for loop end\n");
		} else {
			if (arg[1] != '\n') {
				fprintf(stderr, "Unexpected argument `%s'\n",
					arg);
				exit(1);
			}

			switch (arg[0]) {
			case 'w':
				/* while */
				if (depth == 0 && do_loop) {
					print(c, "%% do loop end detected\n");
					goto out;
				}
				print(c, "%% while loop start\n");
				advancedness += loop(c, here, angle, 0);
				print(c, "%% while loop end\n");
				break;

			case '.':
				/* Statement */
				break;

			case ';':
				/* End of loop / if */
				if (depth == 0)
					goto out;
				break;

			case '{':
				depth++;
				break;

			case '}':
				depth--;
				/* End of loop / if block */
				if (depth == 0 && !do_loop)
					goto out;
				break;

			case '!':
				advancedness++;
				break;

			default:
				fprintf(stderr, "Unexpected argument `%s'\n",
					arg);
				exit(1);
			}
			
			*here = draw_line(1, advancedness, *angle, *here, c);
		}
		*angle += random()%MAX_VARIANCE-MAX_VARIANCE/2;
		if (*angle < 0) *angle += 360;
		else if (*angle > 360) *angle -= 360;
	}
 out:
	return advancedness;
}

static void init_context(struct context *c, struct coord start)
{
	c->bound.min.x = c->bound.max.x = 0;
	c->bound.min.y = c->bound.max.y = 0;
	c->last_end.x = start.x;
	c->last_end.y = start.y;
	c->buffer = malloc(100);
	c->buffer_size = 100;

	printf("%.2f %.2f moveto\n", c->last_end.x, c->last_end.y);
}

/* Reads standard input for data stream.   Args: function name. */
int main(int argc, const char *argv[])
{
	struct context c;
	struct coord start = { 0, 0 };
	unsigned int i, total = 0;
	float angle = 0;

	/* Sum function name to get seed. */
	for (i = 0; i < strlen(argv[1]); i++) total += i;
	srandom(total);

	init_context(&c, start);
	iterate(&c, &start, &angle, 1, 0);

	/* Finish it */
	dump(&c);
	printf("0 0 moveto stroke\n");
	/* Never want zero width or height; pad by 1 */
	printf("%% Bound %.2f %.2f %.2f %.2f\n",
	       c.bound.min.x-1, c.bound.min.y-1, c.bound.max.x+1, c.bound.max.y+1);

	return 0;
}
