/*
 * Copyright (c) 2008 Bret S. Lambert <blambert@openbsd.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

#define THREAD_COUNT 64

#define TEXT	"barnacles"
#define	TEXT_N	"barnacles\n"

void	run_threads(void (*)(void *), void *);

static pthread_rwlock_t	start;
static void	(*real_func)(void *);

static void *
thread(void *arg)
{
	int	r;

	if ((r = pthread_rwlock_rdlock(&start)))
		errx(1, "could not obtain lock in thread: %s", strerror(r));
	real_func(arg);
	if ((r = pthread_rwlock_unlock(&start)))
		errx(1, "could not release lock in thread: %s", strerror(r));
	return NULL;
}

void
run_threads(void (*func)(void *), void *arg)
{
	pthread_t	self, pthread[THREAD_COUNT];
	int	i, r;

	self = pthread_self();
	real_func = func;
	if ((r = pthread_rwlock_init(&start, NULL)))
		errx(1, "could not initialize lock: %s", strerror(r));

	if ((r = pthread_rwlock_wrlock(&start)))		/* block */
		errx(1, "could not lock lock: %s", strerror(r));

	for (i = 0; i < THREAD_COUNT; i++)
		if ((r = pthread_create(&pthread[i], NULL, thread, arg))) {
			warnx("could not create thread: %s", strerror(r));
			pthread[i] = self;
		}


	if ((r = pthread_rwlock_unlock(&start)))		/* unleash */
		errx(1, "could not release lock: %s", strerror(r));

	sleep(1);

	if ((r = pthread_rwlock_wrlock(&start)))		/* sync */
		errx(1, "parent could not sync with children: %s",
		    strerror(r));

	for (i = 0; i < THREAD_COUNT; i++)
		if (! pthread_equal(pthread[i], self) &&
		    (r = pthread_join(pthread[i], NULL)))
			warnx("could not join thread: %s", strerror(r));
}

