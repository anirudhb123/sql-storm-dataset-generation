WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL 

    UNION ALL 

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
, ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM 
        movie_hierarchy mh
)
, movie_cast AS (
    SELECT 
        mt.id AS movie_id,
        ac.name AS actor_name,
        COUNT(ci.id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ac ON ci.person_id = ac.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    WHERE 
        ci.nr_order = 1 
    GROUP BY 
        mt.id, ac.name
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    rm.rank,
    mc.actor_name,
    mc.actor_count
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_cast mc ON rm.movie_id = mc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rank;

This query does the following:

1. **CTE for Movie Hierarchy**: It creates a recursive CTE that builds a hierarchy of movies linked by the `movie_link` table, capturing the relationship depth.
2. **Ranking Movies**: It uses a second CTE to rank movies by their production year and hierarchy level.
3. **Movie Cast Info**: A subquery aggregates actors participating in movies, counting them and filtering for lead roles.
4. **Final Selection**: The main query joins the ranked movies with the movie cast information to provide a comprehensive view of the top 5 ranked movies, including their titles, production years, ranks, and actor details, ordered by year and rank.

This elaborate query incorporates outer joins, CTEs, window functions, and aggregation to create a rich result set suitable for performance benchmarking.
