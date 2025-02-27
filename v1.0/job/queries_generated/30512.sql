WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM aka_title mt
    WHERE mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mk.linked_movie_id,
        ak.title,
        ak.production_year,
        mh.level + 1
    FROM movie_link mk
    JOIN aka_title ak ON mk.linked_movie_id = ak.id
    JOIN movie_hierarchy mh ON mk.movie_id = mh.movie_id
),
actor_info AS (
    SELECT 
        an.name,
        ci.movie_id,
        ci.person_role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY an.name) AS actor_order,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM cast_info ci
    JOIN aka_name an ON ci.person_id = an.person_id
),
movies_with_actor_count AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(SUM(ai.total_actors), 0) AS actor_count
    FROM movie_hierarchy mh
    LEFT JOIN actor_info ai ON mh.movie_id = ai.movie_id
    GROUP BY mh.movie_id, mh.title, mh.production_year
),
movie_genres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM movie_keyword mk
    JOIN keyword kt ON mk.keyword_id = kt.id
    JOIN actor_info ai ON mk.movie_id = ai.movie_id
    GROUP BY mt.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ma.actor_count, 0) AS actor_count,
    COALESCE(mg.genres, 'No Genres') AS genres,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_classification
FROM movie_hierarchy mh
LEFT JOIN movies_with_actor_count ma ON mh.movie_id = ma.movie_id
LEFT JOIN movie_genres mg ON mh.movie_id = mg.movie_id
WHERE mh.level = 1
ORDER BY mh.production_year DESC, mh.title;

This query contains:
- Recursive CTE (`movie_hierarchy`) to construct a hierarchy of movies based on linked movies.
- Another CTE (`actor_info`) to gather aggregate information regarding actors in each movie and provide ranking.
- A CTE (`movies_with_actor_count`) uses window functions to calculate the number of actors per movie.
- A CTE (`movie_genres`) to collect genres related to each movie.
- The main query combines these datasets, includes case statements, and handles NULLs using COALESCE.
- The final output is ordered by production year and title, delivering a comprehensive view of movie data along with derived information.
