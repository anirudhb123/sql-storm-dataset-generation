WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        at.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
),
company_movies AS (
    SELECT 
        mc.movie_id,
        cs.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        movie_companies mc
    JOIN 
        company_name cs ON mc.company_id = cs.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info c ON mc.movie_id = c.movie_id
    WHERE 
        ct.kind IN ('Producer', 'Director')
    GROUP BY 
        mc.movie_id, cs.name, ct.kind
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS rank,
        COALESCE(c.total_cast, 0) AS total_cast
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        company_movies c ON mh.movie_id = c.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.rank,
    rm.total_cast
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
    AND rm.total_cast IS NOT NULL
ORDER BY 
    rm.production_year DESC, rm.rank;

**Explanation:**
1. **Recursive CTE (`movie_hierarchy`)**: This CTE constructs a hierarchy of movies starting from titles produced from the year 2000 onward, recursively including linked movies up to a level of 3 (to include movies connected to the original title).
2. **Aggregation in `company_movies`**: This CTE aggregates data about movie companies (for 'Producer' and 'Director' types), calculating the total number of distinct cast members for each movie.
3. **Ranking in `ranked_movies`**: This part ranks movies within their kind based on the production year.
4. **Final Selection**: The outer query retrieves the top 5 ranked movies while filtering out any movies without a total cast, ordering them by the production year and rank. 

This query structure provides a robust performance benchmark due to its use of recursion, aggregation, window functions, and filtering on various criteria.
