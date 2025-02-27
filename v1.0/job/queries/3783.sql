WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(ki.info, 'No description') AS description,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    LEFT JOIN 
        (SELECT movie_id, STRING_AGG(info, '; ') AS info FROM movie_info GROUP BY movie_id) ki ON t.id = ki.movie_id
),
CastCount AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.description,
    cc.actor_count,
    cd.companies,
    CASE 
        WHEN cc.actor_count > 10 THEN 'Large Cast'
        WHEN cc.actor_count > 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    COALESCE(NULLIF(cd.companies, ''), 'No companies listed') AS company_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CastCount cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rn = 1 
    AND (rm.title ILIKE '%Avengers%' OR rm.title ILIKE '%Batman%')
ORDER BY 
    rm.movie_id DESC;
