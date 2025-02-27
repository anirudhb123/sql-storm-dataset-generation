WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        SUM(CASE WHEN ca.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_note,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
        LEFT JOIN cast_info ca ON t.id = ca.movie_id
        LEFT JOIN aka_name a ON ca.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

MovieCompanyCTE AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT co.kind, ', ') AS company_types,
        COUNT(DISTINCT mc.id) AS total_companies
    FROM 
        movie_companies mc
        JOIN company_name c ON mc.company_id = c.id
        JOIN company_type co ON mc.company_type_id = co.id
    GROUP BY 
        mc.movie_id
),

BenchmarkResults AS (
    SELECT 
        m.title,
        m.production_year,
        m.total_cast,
        m.cast_with_note,
        mc.companies,
        mc.company_types,
        m.actors,
        m.year_rank,
        CASE 
            WHEN m.total_cast > 10 THEN 'Large Cast'
            WHEN m.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size,
        CASE
            WHEN m.production_year < 2000 THEN 'Classic'
            ELSE 'Modern'
        END AS movie_era
    FROM 
        RecursiveMovieCTE m
        LEFT JOIN MovieCompanyCTE mc ON m.title_id = mc.movie_id
)

SELECT 
    *,
    CASE 
        WHEN total_cast IS NULL THEN 'No Cast Info'
        WHEN total_cast = 0 THEN 'No Actors'
        ELSE 'Have Actors'
    END AS actor_status,
    TRIM(BOTH ' ' FROM (actors[1]::text || ' - ' || companies || ' [' || movie_era || ']')) AS movie_summary
FROM 
    BenchmarkResults
WHERE 
    year_rank <= 10  -- Filter to only the top 10 movies per year
ORDER BY 
    production_year DESC, 
    year_rank ASC;
