WITH Recursive_Title AS (
    SELECT 
        t.title,
        t.production_year,
        t.id AS title_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), CTE_Cast_Info AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(r.role) AS prominent_role,
        MIN(r.role) AS minor_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
), Movie_Company_Info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name) AS companies_involved,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title,
    rt.production_year,
    ci.total_cast,
    ci.prominent_role,
    ci.minor_role,
    CASE 
        WHEN ci.total_cast IS NULL THEN 'No cast information available'
        ELSE 'Data available'
    END AS cast_info_status,
    mci.companies_involved,
    mci.company_types
FROM 
    Recursive_Title rt
LEFT JOIN 
    CTE_Cast_Info ci ON rt.title_id = ci.movie_id
LEFT JOIN 
    Movie_Company_Info mci ON rt.title_id = mci.movie_id
WHERE 
    rt.rn <= 5  -- Only considering the latest 5 movies per production year
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC
LIMIT 100;

-- Additional complexity: Including a subquery for full name extraction
WITH Full_Names AS (
    SELECT 
        a.person_id,
        CONCAT(a.name, ' (', a.md5sum, ')') AS full_name
    FROM 
        aka_name a
    WHERE 
        a.name IS NOT NULL
)

SELECT 
    fn.full_name,
    t.title,
    c.total_cast,
    mci.companies_involved
FROM 
    Full_Names fn
JOIN 
    cast_info c ON fn.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    Movie_Company_Info mci ON t.id = mci.movie_id
WHERE 
    t.production_year >= 2000 
    AND (mci.companies_involved IS NOT NULL OR c.total_cast > 5)
ORDER BY 
    fn.full_name;
