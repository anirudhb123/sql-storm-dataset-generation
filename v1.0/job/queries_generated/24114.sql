WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyNames AS (
    SELECT 
        c.id AS company_id,
        c.name,
        c.country_code,
        ROW_NUMBER() OVER (PARTITION BY c.country_code ORDER BY LENGTH(c.name) DESC) AS country_rank
    FROM 
        company_name c
    WHERE 
        c.name ILIKE 'A%'
),
MovieRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL OR ci.note <> 'Special Appearance'
    GROUP BY 
        ci.movie_id, rt.role
),
CombinedData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cn.name AS company_name,
        mr.role,
        mr.role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        CompanyNames cn ON mc.company_id = cn.company_id AND cn.country_rank = 1
    LEFT JOIN 
        MovieRoles mr ON rm.movie_id = mr.movie_id
)
SELECT 
    cd.title,
    cd.production_year,
    COALESCE(cd.company_name, 'Independent') AS preferred_company,
    COUNT(cd.role) AS total_roles,
    STRING_AGG(DISTINCT cd.role, ', ') AS role_list
FROM 
    CombinedData cd
WHERE 
    cd.production_year BETWEEN 2000 AND 2023
GROUP BY 
    cd.title, cd.production_year, cd.company_name
HAVING 
    COUNT(cd.role) >= 1 
ORDER BY 
    cd.production_year DESC, total_roles DESC;

