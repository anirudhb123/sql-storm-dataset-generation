WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        COUNT(CASE WHEN it.id = 1 THEN 1 END) AS has_overview,  
        COUNT(CASE WHEN it.id = 2 THEN 1 END) AS has_tagline     
    FROM 
        movie_info mi
    INNER JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title AS Movie_Title,
    rm.production_year AS Year,
    rm.actor_names AS Cast,
    cc.company_count AS Production_Companies,
    mi.has_overview AS Has_Overview,
    mi.has_tagline AS Has_Tagline
FROM 
    RankedMovies rm
FULL OUTER JOIN 
    CompanyCounts cc ON rm.title_id = cc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.title_id = mi.movie_id
WHERE 
    (rm.rank_by_cast = 1 OR cc.company_count IS NULL) 
    AND (rm.production_year < 2000 OR mi.has_overview = 1)
ORDER BY 
    rm.production_year DESC, 
    cc.company_count DESC NULLS LAST;