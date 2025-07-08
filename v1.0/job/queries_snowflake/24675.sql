
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, LENGTH(t.title) ASC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.title NOT LIKE '%Unreleased%'
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.note LIKE '%main%' THEN 1 ELSE 0 END) AS main_cast_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        LISTAGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
ExtendedDetails AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        cd.total_cast,
        cd.main_cast_count,
        mc.num_companies,
        mc.company_names,
        COALESCE(NULLIF(tr.role, ''), 'unknown') AS role_description
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.title_id = cd.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.title_id = mc.movie_id
    LEFT JOIN 
        role_type tr ON tr.id = cd.main_cast_count
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    ed.title,
    ed.production_year,
    ed.total_cast,
    ed.main_cast_count,
    ed.num_companies,
    ed.company_names,
    ed.role_description,
    CASE 
        WHEN ed.total_cast IS NULL THEN 'No Cast Information'
        WHEN ed.total_cast > 10 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    ExtendedDetails ed
WHERE 
    ed.num_companies > 2
ORDER BY 
    ed.production_year DESC, 
    ed.total_cast DESC NULLS LAST
LIMIT 10;
