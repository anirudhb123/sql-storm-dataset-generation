WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming kind_id = 1 is for movies
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title mt
    INNER JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
RankedActors AS (
    SELECT 
        ca.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS actor_rank,
        COUNT(*) OVER (PARTITION BY ca.person_id) AS total_movies
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ra.name, 'Unknown Actor') AS main_actor_name,
    COALESCE(rk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN ra.actor_rank IS NOT NULL THEN ra.actor_rank
        ELSE -1
    END AS actor_rank,
    CASE 
        WHEN ra.total_movies IS NULL THEN 0
        ELSE ra.total_movies
    END AS total_movies,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    COUNT(DISTINCT ai.id) AS info_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedActors ra ON ra.total_movies > 1 
    AND ra.actor_rank = 1 -- Get the main actor
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info ai ON mh.movie_id = ai.movie_id
LEFT JOIN 
    MovieKeywords rk ON mh.movie_id = rk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, ra.name, ra.actor_rank, ra.total_movies
ORDER BY 
    mh.production_year DESC, mh.title;

This SQL query performs the following:

1. **CTE for Recursive Hierarchy**: It creates a recursive common table expression (CTE) named `MovieHierarchy` to build a hierarchy of movies, linked by relationships stored in the `movie_link` table.

2. **Ranked Actors**: It computes the rank of actors for each movie using window functions in the `RankedActors` CTE, counting their appearances.

3. **Movie Keywords Aggregation**: It aggregates the keywords for each movie in the `MovieKeywords` CTE using `STRING_AGG`.

4. **Main Query**: Combines all data with multiple joins (including outer joins) and computes counts, handling NULLs, and adding case logic for better output clarity.

5. **Final Output**: Outputs the `movie_id`, title, production year, main actor, keywords, rank, total movies, number of production companies, and info count, ordered by the year of production and title.

This complex SQL query stresses performance evaluation by leveraging various SQL features.
