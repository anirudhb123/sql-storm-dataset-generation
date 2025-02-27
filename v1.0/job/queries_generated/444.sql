WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mii.info, ', ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type iti ON mi.info_type_id = iti.id
    LEFT JOIN 
        movie_info_idx mii ON mi.movie_id = mii.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    cd.company_name,
    cd.company_type,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.title = (
        SELECT 
            title 
        FROM 
            aka_title 
        WHERE 
            id = cd.movie_id 
        LIMIT 1
    )
LEFT JOIN 
    MovieInfo mi ON rm.production_year = 2020 AND rm.rank = 1  -- Considering only top-ranked movie of 2020
WHERE 
    cd.company_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
