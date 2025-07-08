WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        1 AS depth
    FROM title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM movie_link ml
    JOIN title m ON ml.linked_movie_id = m.id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
, GenreStats AS (
    SELECT 
        kt.keyword AS genre,
        COUNT(DISTINCT mh.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_year
    FROM MovieHierarchy mh
    JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    JOIN keyword kt ON mk.keyword_id = kt.id
    JOIN title m ON mh.movie_id = m.id
    GROUP BY kt.keyword
)
, TopActors AS (
    SELECT 
        ak.name AS actor_name, 
        COUNT(ci.movie_id) AS movies_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN MovieHierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY ak.name
    ORDER BY movies_count DESC
    LIMIT 10
)
SELECT 
    g.genre,
    g.movie_count,
    g.avg_year,
    ta.actor_name,
    COALESCE(ta.movies_count, 0) AS actor_movies_count
FROM GenreStats g
LEFT JOIN TopActors ta ON g.movie_count = ta.movies_count
ORDER BY g.movie_count DESC, g.avg_year ASC;
