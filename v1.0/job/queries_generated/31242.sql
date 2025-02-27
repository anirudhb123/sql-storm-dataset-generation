WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, 
           mt.title, 
           NULL::INTEGER AS parent_id, 
           0 AS depth 
    FROM title mt 
    WHERE mt.episode_of_id IS NULL -- Starting with top-level movies (non-episode titles)

    UNION ALL

    SELECT mt.id, 
           mt.title, 
           mh.movie_id AS parent_id, 
           mh.depth + 1 
    FROM title mt 
    INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
ActorStats AS (
    SELECT a.id, 
           ak.name AS actor_name,
           COUNT(c.movie_id) AS total_movies,
           AVG(ty.production_year) AS avg_production_year,
           ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY COUNT(c.movie_id) DESC) AS rank
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN aka_title ty ON c.movie_id = ty.movie_id
    GROUP BY a.id, ak.name
),
MoviesWithKeyword AS (
    SELECT m.id AS movie_id,
           STRING_AGG(k.keyword, ', ') AS keywords
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id
)
SELECT mh.movie_id,
       mh.title AS movie_title,
       COALESCE(ak.actor_name, 'Unknown Actor') AS actor_name,
       COALESCE(mkw.keywords, 'No Keywords') AS keywords,
       stats.total_movies,
       stats.avg_production_year,
       mh.depth
FROM MovieHierarchy mh
LEFT JOIN ActorStats stats ON stats.rank = 1
LEFT JOIN aka_title at ON mh.movie_id = at.id
LEFT JOIN MoviesWithKeyword mkw ON mh.movie_id = mkw.movie_id
OUTER APPLY (SELECT ak.name 
              FROM aka_name ak 
              JOIN cast_info c ON ak.person_id = c.person_id 
              WHERE c.movie_id = mh.movie_id 
              AND ak.name IS NOT NULL 
              ORDER BY c.nr_order 
              LIMIT 1) AS ak
WHERE mh.depth <= 3 -- Limiting the query to a specific depth
ORDER BY mh.movie_id, stats.total_movies DESC;
This SQL query showcases several advanced constructs, including:

- Recursive Common Table Expressions (CTEs) to build a hierarchy of movies and episodes.
- Aggregated statistics for actors, including average production year and total movies.
- A combination of outer and inner joins to gather all relevant movie, actor, and keyword data.
- String aggregation to fetch multiple keywords associated with each movie.
- NULL logic handled with `COALESCE` to provide default values when no data exists.
