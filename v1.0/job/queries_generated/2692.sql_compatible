
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT mi.info) FILTER (WHERE mi.info_type_id = 1) AS tagline_count
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        MAX(co.name) AS primary_company
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cd.cast_count, 0) AS total_cast,
    COALESCE(cd.actor_names, 'No actors') AS actor_list,
    COALESCE(cmp.company_count, 0) AS total_companies,
    cmp.primary_company,
    rm.tagline_count,
    CASE 
        WHEN rm.year_rank <= 5 THEN 'Top Release'
        ELSE 'Regular Release'
    END AS release_status
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyDetails cmp ON rm.movie_id = cmp.movie_id
WHERE 
    rm.production_year >= 2000 
    AND (COALESCE(cd.cast_count, 0) > 0 OR COALESCE(cmp.company_count, 0) > 0)
ORDER BY 
    rm.production_year DESC, rm.title ASC
LIMIT 50;
