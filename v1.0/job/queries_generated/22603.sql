WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn,
        COUNT(*) OVER (PARTITION BY m.production_year) AS title_count
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
CastingInfo AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MoviesWithActorsCompanies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        coalesce(ci.actor_count, 0) AS actor_count,
        coalesce(ci.actors, 'No actors') AS actors,
        coalesce(comp.companies, 'No companies') AS companies,
        CASE 
            WHEN m.title_count > 0 AND ci.actor_count > 0 THEN 
                (ci.actor_count * 1.0 / m.title_count)
            ELSE 0
        END AS actor_to_title_ratio
    FROM 
        RankedMovies m
    LEFT JOIN 
        CastingInfo ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        MovieCompanies comp ON m.movie_id = comp.movie_id
)
SELECT 
    ma.title,
    ma.production_year,
    ma.actors,
    ma.companies,
    ma.actor_to_title_ratio,
    COUNT(*) OVER (PARTITION BY CASE WHEN ma.actor_to_title_ratio > 1 THEN 'High' ELSE 'Low' END) AS classification_count,
    MAX(ma.actor_to_title_ratio) OVER () AS max_actor_to_title_ratio,
    CASE 
        WHEN COUNT(ma.movie_id) FILTER (WHERE ma.actor_to_title_ratio IS NULL) > 0 THEN 'NULL Actor Ratio'
        ELSE 'Values Present'
    END AS ratio_null_logic
FROM 
    MoviesWithActorsCompanies ma
WHERE 
    ma.production_year >= (SELECT MIN(production_year) FROM aka_title WHERE production_year IS NOT NULL)
    AND ma.actor_to_title_ratio IS NOT NULL
ORDER BY 
    ma.production_year DESC,
    ma.actor_count DESC;
