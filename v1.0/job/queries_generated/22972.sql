WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ml.linked_movie_id,
        lvl AS hierarchy_level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mh.movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ml.linked_movie_id,
        mh.hierarchy_level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.hierarchy_level < 5
),
movie_cast AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mc.cast_names,
        mc.num_actors,
        ROW_NUMBER() OVER (PARTITION BY mh.hierarchy_level ORDER BY mc.num_actors DESC) AS rank_within_level
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_cast mc ON mh.movie_id = mc.movie_id
)
SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    r.cast_names,
    r.num_actors,
    r.rank_within_level
FROM 
    ranked_movies r
WHERE 
    r.rank_within_level <= 3 
    AND r.production_year BETWEEN 1990 AND 2020
    AND r.cast_names IS NOT NULL
ORDER BY 
    r.hierarchy_level, r.rank_within_level
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;

### Explanation:

1. The first CTE (`movie_hierarchy`) uses a recursive query to build a hierarchy of movies based on their linked relationships, filtering by production year.
2. The second CTE (`movie_cast`) aggregates cast information per movie, concatenating actor names and counting distinct actors.
3. The third CTE (`ranked_movies`) ranks these movies per hierarchy level, based on the number of actors in descending order.
4. The final `SELECT` statement retrieves only the top 3 movies per level in the hierarchy from 1990 to 2020, along with associated casting information, while applying pagination (with `OFFSET` and `FETCH`).
5. The constructs used, including CTEs, aggregation, window functions, and filtering for NULL checks, showcase how to perform complex queries on the provided movie dataset.
