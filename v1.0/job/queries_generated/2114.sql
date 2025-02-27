WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn,
        COUNT(DISTINCT k.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
), CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        SUM(CASE WHEN ci.kind = 'Director' THEN 1 ELSE 0 END) AS director_count
    FROM 
        cast_info c
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    GROUP BY 
        c.movie_id
), MovieCompany AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.country_code) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.actor_count, 0) AS actor_count,
    COALESCE(cd.director_count, 0) AS director_count,
    COALESCE(mc.company_count, 0) AS company_count,
    rm.keyword_count,
    CASE 
        WHEN rm.keyword_count > 10 THEN 'Highly Popular' 
        WHEN rm.keyword_count BETWEEN 5 AND 10 THEN 'Moderately Popular' 
        ELSE 'Less Popular' 
    END AS popularity
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.title_id = cd.movie_id
LEFT JOIN 
    MovieCompany mc ON rm.title_id = mc.movie_id
WHERE 
    rm.rn <= 5 OR (cd.actor_count IS NULL AND rm.production_year < 2000)
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC;
