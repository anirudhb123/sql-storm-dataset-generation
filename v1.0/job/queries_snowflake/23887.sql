
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastHighlights AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT m.info, '; ') WITHIN GROUP (ORDER BY m.info) AS movie_details
    FROM 
        movie_companies mc
    LEFT JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    WHERE 
        mc.note IS NULL OR mc.note NOT LIKE '%uncredited%'
    GROUP BY 
        mc.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        co.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    ch.actor_count,
    ch.actors,
    mi.movie_details,
    cd.companies,
    CASE 
        WHEN cd.companies IS NULL THEN 'No Company Info'
        ELSE 'Company Info Available'
    END AS company_info_status,
    (SELECT COUNT(*) 
     FROM movie_keyword mk 
     WHERE mk.movie_id = rm.movie_id) AS keyword_count,
    NULLIF((SELECT ROUND(AVG(m.production_year)) FROM aka_title m), 0) AS avg_production_year
FROM 
    RankedMovies rm
LEFT JOIN 
    CastHighlights ch ON rm.movie_id = ch.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 50;
