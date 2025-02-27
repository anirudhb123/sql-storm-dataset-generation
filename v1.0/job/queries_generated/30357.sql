WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL  -- Start with top-level movies (not episodes)

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),

cast_with_names AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        ci.nota AS acting_note,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS name_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
),

company_data AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) OVER (PARTITION BY mc.movie_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    STRING_AGG(DISTINCT cn.company_name, ', ') AS production_companies,
    STRING_AGG(DISTINCT ca.actor_name, ', ') AS cast,
    MAX(ca.acting_note) AS last_actor_note, 
    mh.level,
    COUNT(DISTINCT ca.name_rank) AS actor_count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_with_names ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    company_data cn ON mh.movie_id = cn.movie_id
WHERE 
    mh.production_year >= 2000 
    AND ca.actor_name IS NOT NULL
GROUP BY 
    mh.movie_title, 
    mh.production_year, 
    mh.level
HAVING 
    COUNT(DISTINCT ca.actor_name) > 2
ORDER BY 
    mh.production_year DESC,
    mh.movie_title;

This query works through multiple parts:
1. **Recursive CTE (`movie_hierarchy`)**: It builds a hierarchy of movies and their related episodes, filtering out anything that is an episode.
2. **CTE (`cast_with_names`)**: It retrieves cast information by joining with actor names and also calculates a ranking for each actor in a specific movie.
3. **CTE (`company_data`)**: It fetches production companies associated with each movie, counting the number for potential filtering.
4. **Main SELECT Statement**: It aggregates results by movie title and year, calculating distinct lists of production companies and cast members, as well as filtering on predicates and having multiple criteria in the `HAVING` clause.

The query includes window functions for ranking, aggregate functions for string aggregation and counting, and utilizes outer joins to include all movies even if there are no cast members or production companies associated with them.
