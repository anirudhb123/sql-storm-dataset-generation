WITH RECURSIVE movie_cycle AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        c.name AS company_name,
        CASE 
            WHEN co.kind IS NULL THEN 'Unknown'
            ELSE co.kind 
        END AS company_type,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.name) AS cte_row_num
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_name AS c ON c.id = mc.company_id
    LEFT JOIN 
        company_type AS co ON co.id = mc.company_type_id
    WHERE 
        m.production_year >= 2000
        AND m.kind_id IS NOT NULL
    ORDER BY 
        m.production_year DESC
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
movie_cast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN r.role IS NOT NULL THEN 1 ELSE 0 END) AS roles_assigned,
        MIN(r.role) AS first_role,
        MAX(r.role) AS last_role
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS r ON r.id = ci.role_id 
    GROUP BY 
        ci.movie_id
),
final_output AS (
    SELECT 
        mc.movie_id,
        mc.title,
        mc.company_name,
        mc.company_type,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(mc2.total_cast, 0) AS total_cast,
        COALESCE(mc2.roles_assigned, 0) AS roles_assigned,
        mc2.first_role,
        mc2.last_role
    FROM 
        movie_cycle AS mc
    LEFT JOIN 
        movie_keywords AS mk ON mk.movie_id = mc.movie_id
    LEFT JOIN 
        movie_cast AS mc2 ON mc2.movie_id = mc.movie_id
    WHERE 
        (mc.cte_row_num <= 5 OR mc.company_type != 'Distributor')  
)
SELECT 
    f.movie_id,
    f.title,
    f.company_name,
    f.company_type,
    f.keywords,
    f.total_cast,
    f.roles_assigned,
    f.first_role,
    f.last_role,
    CASE 
        WHEN f.roles_assigned = 0 THEN 'No cast roles assigned'
        WHEN f.total_cast > 10 THEN 'Highly Casted'
        ELSE 'Standard Cast'
    END AS casting_description
FROM 
    final_output AS f
WHERE 
    f.keywords LIKE '%Action%' OR f.keywords IS NULL  
ORDER BY 
    f.total_cast DESC, f.movie_id ASC;