WITH RankedMovies AS (
    SELECT 
        mt.movies_id,
        mt.title,
        mt.production_year,
        COUNT(c.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(c.id) DESC) as rn
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS distinct_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mt.info, ', ') AS info_list
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_info_idx mt ON mi.movie_id = mt.movie_id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    cd.company_name,
    cd.company_type,
    COALESCE(mi.info_list, 'No Info Available') AS movie_information,
    CASE 
        WHEN rm.actor_count > 10 THEN 'Blockbuster'
        WHEN rm.actor_count BETWEEN 5 AND 10 THEN 'Average'
        ELSE 'Low Profile'
    END AS movie_profile
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movies_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movies_id = mi.movie_id
WHERE 
    rm.rn <= 5 
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
