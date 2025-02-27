WITH RecursiveCTE AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS aka_name,
        ak.person_id,
        ak.md5sum,
        ROW_NUMBER() OVER(PARTITION BY ak.person_id ORDER BY ak.id) AS row_num
    FROM 
        aka_name ak
    WHERE 
        ak.name IS NOT NULL
),
MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
PersonRoleInfo AS (
    SELECT 
        ci.person_id,
        rt.role,
        COUNT(*) AS role_count,
        AVG(ci.nr_order) AS avg_order
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, rt.role
),
CombinedInfo AS (
    SELECT 
        m.title,
        m.production_year,
        p.aka_name,
        pr.role,
        pr.role_count,
        pr.avg_order,
        CASE 
            WHEN pr.role_count IS NULL THEN 'No roles assigned'
            ELSE 'Roles assigned'
        END AS role_status
    FROM 
        MovieCTE m
    JOIN 
        RecursiveCTE p ON p.row_num = 1
    LEFT JOIN 
        PersonRoleInfo pr ON p.person_id = pr.person_id
)
SELECT 
    title,
    production_year,
    aka_name,
    role,
    role_count,
    avg_order,
    role_status
FROM 
    CombinedInfo
WHERE 
    (role IS NOT NULL OR role_status = 'No roles assigned')
    AND (production_year IS NOT NULL OR aka_name IS NOT NULL)
ORDER BY 
    production_year DESC, 
    title ASC
LIMIT 100 OFFSET 0;

