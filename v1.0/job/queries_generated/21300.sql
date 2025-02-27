WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastByRole AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL OR ci.note NOT LIKE '%uncredited%'
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
ComplexJoin AS (
    SELECT 
        r.title,
        c.person_id,
        c.role,
        mk.keywords,
        COUNT(mk.keywords) OVER (PARTITION BY r.title) AS keyword_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        CastByRole c ON r.title_id = c.movie_id AND c.role_rank = 1
    LEFT JOIN 
        MoviesWithKeywords mk ON r.title_id = mk.movie_id
    WHERE 
        r.year_rank = 1
)
SELECT 
    cj.title,
    COUNT(DISTINCT cj.person_id) AS total_actors,
    MAX(COALESCE(cj.keywords, 'No Keywords')) AS keywords,
    SUM(CASE WHEN cj.role IN ('Director', 'Producer') THEN 1 ELSE 0 END) AS key_roles_count,
    ARRAY_AGG(DISTINCT cj.role) FILTER (WHERE cj.role IS NOT NULL) AS all_roles
FROM 
    ComplexJoin cj
GROUP BY 
    cj.title
ORDER BY 
    total_actors DESC
LIMIT 10 OFFSET 5;

This SQL query performs several complex operations, including:

1. **Common Table Expressions (CTEs)** for ranking movies, collecting cast by role, and gathering associated keywords.
2. **ROW_NUMBER() Window Function** to rank movies by production year and to number cast members by their `nr_order`.
3. **STRING_AGG** to aggregate keywords associated with each movie as a single string.
4. **LEFT JOINs** to associate movies with primary actors and their keywords.
5. Uses **NULL logic** in the condition of the note field to exclude uncredited roles.
6. **FILTER clause** to gather unique roles while avoiding NULL values.
7. The final selection includes a count of distinct actors, the maximum or a default string for keywords, and a summation of actors with significant roles.
8. Orders the results by total actors and implements pagination with LIMIT and OFFSET.
