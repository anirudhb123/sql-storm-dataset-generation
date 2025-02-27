
WITH TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id, t.title, t.production_year
), CastRoles AS (
    SELECT 
        ci.movie_id,
        ct.kind AS role_type,
        COUNT(ci.person_id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id, ct.kind
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
), RankedMovies AS (
    SELECT 
        ti.title,
        ti.production_year,
        COALESCE(cr.total_cast, 0) AS total_cast,
        COALESCE(cmp.company_count, 0) AS company_count,
        ti.keyword_count,
        ROW_NUMBER() OVER (ORDER BY ti.production_year DESC, ti.keyword_count DESC) AS rank
    FROM 
        TitleInfo ti
    LEFT JOIN 
        CastRoles cr ON ti.title_id = cr.movie_id
    LEFT JOIN 
        MovieCompanies cmp ON ti.title_id = cmp.movie_id
)
SELECT 
    title, 
    production_year,
    total_cast, 
    company_count, 
    keyword_count,
    CASE 
        WHEN total_cast = 0 THEN 'No Cast Information'
        WHEN company_count = 0 THEN 'No Company Information'
        ELSE 'Information Available'
    END AS info_status
FROM 
    RankedMovies
WHERE 
    (total_cast > 10 OR company_count > 5)
    AND production_year BETWEEN 2000 AND 2020
ORDER BY 
    rank
FETCH FIRST 100 ROWS ONLY;
