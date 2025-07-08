
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(ci.id) AS role_count,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles_played
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        COUNT(DISTINCT mc.company_id) AS associated_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id, cn.name
)
SELECT 
    rm.title,
    rm.production_year,
    rmc.company_name,
    prc.role_count,
    prc.roles_played,
    rm.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies rmc ON rm.movie_id = rmc.movie_id
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    PersonRoleCounts prc ON ci.person_id = prc.person_id
WHERE 
    (rm.production_year = 2020 OR rm.production_year = 2021)
    AND (prc.role_count IS NOT NULL OR COALESCE(rmc.associated_companies, 0) > 2)
ORDER BY 
    rm.production_year DESC, 
    rm.title_rank,
    rm.keyword_count DESC;
