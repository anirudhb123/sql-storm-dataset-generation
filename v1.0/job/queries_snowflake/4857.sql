WITH RecursiveActorTitles AS (
    SELECT a.id AS actor_id, a.name AS actor_name, t.title AS movie_title, c.nr_order,
           ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS title_order
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year >= 2000
),
FilteredActors AS (
    SELECT actor_id, actor_name, COUNT(DISTINCT movie_title) AS movie_count
    FROM RecursiveActorTitles
    GROUP BY actor_id, actor_name
    HAVING COUNT(DISTINCT movie_title) > 3
),
TopActors AS (
    SELECT actor_id, actor_name, movie_count,
           RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM FilteredActors
)
SELECT ta.actor_name, ta.movie_count, tt.title AS top_movie, tt.production_year,
       COUNT(DISTINCT k.keyword) AS keyword_count
FROM TopActors ta
LEFT JOIN movie_keyword mk ON ta.actor_id = mk.movie_id
LEFT JOIN aka_title tt ON mk.movie_id = tt.id
LEFT JOIN keyword k ON mk.keyword_id = k.id
WHERE ta.rank <= 10
GROUP BY ta.actor_name, ta.movie_count, tt.title, tt.production_year
ORDER BY ta.movie_count DESC, ta.actor_name;
