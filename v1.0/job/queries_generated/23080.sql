WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.movie_id,
        c.person_role_id,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        RankedTitles rt ON c.movie_id = rt.title_id
    GROUP BY 
        c.movie_id, c.person_role_id
    HAVING 
        COUNT(*) > 1
),
MoviesWithAdditionalInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT c.person_id) AS total_actors
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, mk.keyword
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(f.role_count, 0) AS multiple_roles,
    m.total_actors,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year'
        WHEN m.production_year < 2000 THEN 'Before 2000'
        WHEN m.production_year >= 2000 AND m.production_year <= 2010 THEN '2000 - 2010'
        ELSE 'After 2010'
    END AS production_period
FROM 
    MoviesWithAdditionalInfo m
LEFT JOIN 
    FilteredCast f ON m.movie_id = f.movie_id
WHERE 
    m.total_actors > 2
ORDER BY 
    m.production_year DESC, 
    m.total_actors DESC
LIMIT 50;

