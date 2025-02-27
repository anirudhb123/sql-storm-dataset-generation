WITH RECURSIVE MovieHierarchy AS (
    SELECT t.id AS movie_id, t.title AS movie_title, t.production_year, 
           COALESCE(mo.linked_movie_id, -1) AS linked_movie_id
    FROM title t
    LEFT JOIN movie_link mo ON t.id = mo.movie_id
    WHERE t.production_year >= 2000

    UNION ALL

    SELECT t.id AS movie_id, t.title AS movie_title, t.production_year, 
           COALESCE(mo.linked_movie_id, -1) AS linked_movie_id
    FROM title t
    INNER JOIN MovieHierarchy mh ON mh.linked_movie_id = t.id
    LEFT JOIN movie_link mo ON t.id = mo.movie_id
),

ActorMovieInfo AS (
    SELECT a.name AS actor_name, t.title AS movie_title, t.production_year,
           COUNT(DISTINCT ci.id) AS role_count, 
           STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN title t ON ci.movie_id = t.id
    JOIN role_type rt ON ci.role_id = rt.id
    WHERE t.production_year >= 2000
    GROUP BY a.name, t.title, t.production_year
),

AggregateActors AS (
    SELECT actor_name, SUM(role_count) AS total_roles,
           COUNT(DISTINCT movie_title) AS total_movies
    FROM ActorMovieInfo
    GROUP BY actor_name
),

FilteredActors AS (
    SELECT actor_name, total_roles, total_movies,
           RANK() OVER (ORDER BY total_roles DESC) as actor_rank
    FROM AggregateActors
    WHERE total_movies > 5
),

KeywordsWithMovies AS (
    SELECT DISTINCT t.title AS movie_title, k.keyword
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword IS NOT NULL
)

SELECT 
    fh.actor_name,
    fh.total_roles,
    fh.total_movies,
    mh.movie_title,
    mh.production_year,
    kw.keyword
FROM FilteredActors fh
LEFT JOIN MovieHierarchy mh ON fh.total_roles > 10
LEFT JOIN KeywordsWithMovies kw ON mh.movie_title = kw.movie_title
WHERE fh.actor_rank <= 10
ORDER BY fh.total_roles DESC, mh.production_year DESC, kw.keyword;
