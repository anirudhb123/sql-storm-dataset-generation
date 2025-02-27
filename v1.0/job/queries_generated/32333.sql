WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 5  -- Limit depth of recursion to 5 levels
),
ActorDetails AS (
    SELECT 
        ka.person_id,
        ka.name,
        c.movie_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ka.name) AS actor_rank
    FROM 
        aka_name ka
    JOIN 
        cast_info c ON ka.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ad.name AS actor_name,
    ad.role AS actor_role,
    ad.actor_rank,
    mci.company_count,
    mci.company_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorDetails ad ON mh.movie_id = ad.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON mh.movie_id = mci.movie_id
WHERE 
    mh.production_year > 2000  -- Filtering for recent movies
    AND (mci.company_count IS NULL OR mci.company_count > 2)  -- Companies associated with movie
ORDER BY 
    mh.production_year DESC, 
    ad.actor_rank
LIMIT 100;  -- Limit results for performance

### Explanation:
1. **Recursive CTE (MovieHierarchy)**: This CTE is designed to build a hierarchy of linked movies with a depth of 5 levels. It selects the initial movies and recursively finds movies linked to them.

2. **ActorDetails CTE**: This aggregates details about actors, including their names, roles in movies, and ranks them per movie using a window function (`ROW_NUMBER()`).

3. **MovieCompanyInfo CTE**: This calculates the total number of companies associated with each movie and aggregates their names into a single string.

4. **Final Select Statement**: This combines results from the previous CTEs using outer joins:
   - Only includes movies from the year 2000 onwards.
   - Filters for movies associated with more than 2 companies or where the company count is NULL.

5. **Ordering and Limiting**: Results are ordered by year and actor rank before limiting the output to the top 100 entries to maintain performance.

This query combines various SQL constructs to provide a complex data retrieval scenario suitable for performance benchmarking.
