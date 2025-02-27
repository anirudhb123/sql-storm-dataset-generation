WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rnk,
        COUNT(m.id) OVER (PARTITION BY t.id) AS movie_company_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS m ON t.id = m.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

TopRankedTitles AS (
    SELECT 
        title_id,
        title,
        production_year,
        keyword,
        movie_company_count
    FROM 
        RankedTitles
    WHERE 
        rnk = 1
),

PersonRoles AS (
    SELECT 
        c.movie_id,
        p.name,
        r.role,
        COUNT(c.person_role_id) AS role_count
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS p ON c.person_id = p.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, p.name, r.role
),

MoviesWithRoles AS (
    SELECT 
        t.title_id,
        t.title,
        t.production_year,
        pr.name,
        pr.role,
        pr.role_count,
        t.movie_company_count
    FROM 
        TopRankedTitles AS t
    JOIN 
        PersonRoles AS pr ON t.title_id = pr.movie_id
    ORDER BY 
        t.production_year DESC, pr.role_count DESC
)

SELECT 
    m.title,
    m.production_year,
    m.name AS actor_name,
    m.role,
    m.role_count,
    COALESCE(m.movie_company_count, 0) AS company_count,
    CASE 
        WHEN m.role_count > 1 THEN 'Multiple Roles'
        WHEN m.role_count = 1 THEN 'Single Role'
        ELSE 'No Role'
    END AS role_description
FROM 
    MoviesWithRoles AS m
WHERE 
    m.production_year = (SELECT MAX(production_year) FROM TopRankedTitles)
    OR m.movie_company_count = 0
ORDER BY 
    m.production_year DESC,
    m.role_count DESC;

UNION ALL 

SELECT 
    'N/A' AS title,
    NULL AS production_year,
    'Not Applicable' AS actor_name,
    'No Available Roles' AS role,
    0 AS role_count,
    0 AS company_count,
    'No Role' AS role_description
WHERE NOT EXISTS (SELECT 1 FROM MoviesWithRoles);
