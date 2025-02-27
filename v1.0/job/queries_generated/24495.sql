WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mt.movie_id
),
CastStats AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS total_cast,
        COUNT(CASE WHEN r.role IS NOT NULL THEN 1 END) AS roles_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)

SELECT 
    r.title,
    r.production_year,
    COALESCE(g.genres, 'N/A') AS genres,
    cs.total_cast,
    cs.roles_count,
    (cs.total_cast::FLOAT / NULLIF(cs.roles_count, 0)) AS cast_to_role_ratio,
    CASE 
        WHEN cs.roles_count IS NOT NULL AND cs.total_cast > 0 THEN 'Active Cast'
        ELSE 'Inactive Cast'
    END AS cast_status,
    CONCAT('Movie: ', r.title, ', Year: ', r.production_year) AS detailed_info
FROM 
    RankedMovies r
LEFT JOIN 
    MovieGenres g ON r.imdb_index = g.movie_id
LEFT JOIN 
    CastStats cs ON r.imdb_index = cs.movie_id
WHERE 
    r.year_rank = 1
ORDER BY 
    r.production_year DESC, r.title ASC
LIMIT 50;

-- Note:
-- 1. The above query applies outer joins to retrieve movie genre information 
--    and cast statistics for every movie in the ranked list.
-- 2. Window functions rank movies by their production year, 
--    while a correlated subquery inside CTEs gathers movie keywords and cast stats.
-- 3. NULL handling is implemented with COALESCE and NULLIF to avoid division by zero.
-- 4. A case expression is used to categorize movies based on cast activity. 
