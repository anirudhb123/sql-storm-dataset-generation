WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS year_order,
        COUNT(*) OVER (PARTITION BY m.production_year) AS year_count
    FROM 
        aka_title m
),
ActorMovies AS (
    SELECT 
        a.person_id,
        a.movie_id,
        r.role,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY m.production_year DESC) AS rn
    FROM 
        cast_info a
    JOIN 
        role_type r ON a.role_id = r.id
    JOIN 
        RecursiveMovieCTE m ON a.movie_id = m.movie_id
),
FilteredActorMovies AS (
    SELECT 
        am.*,
        COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
        CASE 
            WHEN am.rn = 1 THEN 'Latest Movie'
            WHEN am.rn <= 3 THEN 'Recent Movies'
            ELSE 'Older Movies'
        END AS movie_category
    FROM 
        ActorMovies am
    LEFT JOIN 
        movie_keyword mk ON am.movie_id = mk.movie_id
),
AggregatedResults AS (
    SELECT 
        f.person_id,
        MAX(f.production_year) AS latest_year,
        STRING_AGG(DISTINCT f.movie_keyword, ', ') AS keywords,
        COUNT(*) AS movie_count,
        AVG(f.year_count) / NULLIF(COUNT(DISTINCT f.movie_id), 0) AS avg_movies_per_year
    FROM 
        FilteredActorMovies f
    GROUP BY 
        f.person_id
)
SELECT 
    p.name,
    ar.latest_year,
    ar.keywords,
    ar.movie_count,
    ar.avg_movies_per_year
FROM 
    AggregatedResults ar
JOIN 
    aka_name p ON ar.person_id = p.person_id
WHERE 
    ar.movie_count > 0
    AND ar.keywords IS NOT NULL
ORDER BY 
    ar.latest_year DESC,
    p.name;

This SQL query is designed to benchmark performance using various advanced features. It employs:

1. **Common Table Expressions (CTEs)** for organizing complex logic.
2. **Window functions** for ranking, counting, and averaging.
3. **LEFT JOINs** to handle NULLs properly.
4. **STRING_AGG** for aggregating movie keywords into a single string.
5. **COALESCE** to handle cases with NULL keywords.
6. **NULLIF** to avoid division by zero.
7. **CASE expressions** for dynamic categorization based on movie recency.

This query systematically extracts and aggregates information about actors, their movies, keywords associated with those movies, and organizes results based on various criteria for thorough benchmarking.
