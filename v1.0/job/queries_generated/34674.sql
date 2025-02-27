WITH RECURSIVE RecursiveCTE AS (
    SELECT 
        c.movie_id,
        COUNT(*) AS total_cast,
        SUM(CASE WHEN r.role = 'Actor' THEN 1 ELSE 0 END) AS actor_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(CAST(m.production_year AS text), 'Unknown') AS year_string
    FROM aka_title m
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT cp.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name cp ON mc.company_id = cp.id
    GROUP BY mc.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(r.total_cast, 0) AS total_cast,
    COALESCE(r.actor_count, 0) AS actor_count,
    COALESCE(k.keyword_count, 0) AS keyword_count,
    COALESCE(c.company_count, 0) AS company_count,
    COALESCE(c.company_names, 'No Companies') AS company_names,
    m.year_string
FROM MovieInfo m
LEFT JOIN RecursiveCTE r ON m.movie_id = r.movie_id
LEFT JOIN KeywordStats k ON m.movie_id = k.movie_id
LEFT JOIN CompanyStats c ON m.movie_id = c.movie_id
WHERE m.production_year IS NOT NULL
ORDER BY m.production_year DESC, m.title
LIMIT 100;
