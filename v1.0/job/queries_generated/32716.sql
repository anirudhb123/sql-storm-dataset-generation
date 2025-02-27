WITH RECURSIVE MovieHierarchy AS (
    SELECT m.id AS movie_id, m.title, m.production_year, 1 AS level
    FROM aka_title m
    WHERE m.production_year >= 2000
    
    UNION ALL
    
    SELECT mk.linked_movie_id AS movie_id, mt.title, mt.production_year, mh.level + 1
    FROM movie_link mk
    JOIN MovieHierarchy mh ON mk.movie_id = mh.movie_id
    JOIN aka_title mt ON mk.linked_movie_id = mt.id
),
ActorMovies AS (
    SELECT a.name AS actor_name, t.title AS movie_title, t.production_year,
           ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.id
    WHERE a.name IS NOT NULL AND t.production_year IS NOT NULL
),
RecentMovies AS (
    SELECT movie_id, title, production_year
    FROM MovieHierarchy
    WHERE level = 1
),
MovieKeywords AS (
    SELECT mk.movie_id, k.keyword, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id, k.keyword
),
TopActors AS (
    SELECT actor_name, COUNT(DISTINCT movie_title) AS movie_count
    FROM ActorMovies
    WHERE movie_rank <= 3
    GROUP BY actor_name
    HAVING COUNT(DISTINCT movie_title) > 5
)
SELECT DISTINCT ma.movie_id, ma.title, ma.production_year,
       COALESCE(ta.actor_name, 'Unknown Actor') AS actor_name,
       COALESCE(mk.keyword, 'No Keyword') AS keyword,
       mk.keyword_count
FROM RecentMovies ma
LEFT JOIN ActorMovies ta ON ma.title = ta.movie_title
LEFT JOIN MovieKeywords mk ON ma.movie_id = mk.movie_id
LEFT JOIN TopActors t ON ta.actor_name = t.actor_name
ORDER BY ma.production_year DESC, 
         COALESCE(ta.actor_name, 'Unknown Actor'),
         COALESCE(mk.keyword, 'No Keyword');
