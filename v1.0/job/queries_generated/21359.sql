WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
AggregatedCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        ac.company_count,
        ac.company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        AggregatedCompanies ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.year_rank <= 3 
        AND (ac.company_count IS NULL OR ac.company_count > 1)
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.company_names, 'Unknown') AS companies,
    f.company_count,
    CASE 
        WHEN f.company_count IS NULL THEN 'No companies listed'
        ELSE 'Companies available'
    END AS company_status,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = f.movie_id) AS total_cast_members,
    (SELECT ARRAY_AGG(DISTINCT a.name) 
     FROM aka_name a 
     WHERE a.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = f.movie_id)) AS cast_names
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.title
LIMIT 10;
