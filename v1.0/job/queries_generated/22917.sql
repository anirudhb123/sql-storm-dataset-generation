WITH RECURSIVE MovieCTE AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS row_num
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL
        AND m.production_year >= 2000
        AND m.title IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        COALESCE(ci.kind, 'Unknown Role') AS role,
        COALESCE(c.nr_order, 99) AS order_num,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS role_num
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    WHERE 
        a.name IS NOT NULL
        AND a.md5sum IS NOT NULL
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COALESCE(ARRAY_AGG(DISTINCT cn.name ORDER BY cn.name), '{}') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    m.movie_id, 
    m.title, 
    m.production_year, 
    m.keyword,
    a.name AS actor_name,
    a.role,
    a.order_num,
    mc.companies,
    mc.company_count,
    CASE 
        WHEN mc.company_count > 0 THEN 'Has Companies'
        ELSE 'No Companies'
    END AS company_status,
    CASE 
        WHEN m.row_num % 2 = 0 THEN 'Even Year Movie'
        ELSE 'Odd Year Movie'
    END AS year_category
FROM 
    MovieCTE m
LEFT JOIN 
    ActorDetails a ON m.movie_id = a.movie_id
LEFT JOIN 
    MovieCompanyDetails mc ON m.movie_id = mc.movie_id
WHERE 
    m.keyword IS NOT NULL
    OR a.name IS NOT NULL
ORDER BY 
    m.production_year DESC, 
    m.title ASC,
    a.order_num
LIMIT 50;

-- Including a bizarre CASE that mixes NULL checks and string manipulation
SELECT 
    DISTINCT m.id AS movie_id,
    COALESCE(m.title, 'Untitled Movie') AS title,
    CASE 
        WHEN m.title IS NULL THEN 'Undefined Title'
        ELSE CONCAT('Production Year: ', COALESCE(CAST(m.production_year AS TEXT), 'N/A'))
    END AS movie_description,
    CASE 
        WHEN EXISTS (SELECT 1 FROM aka_title WHERE title = m.title AND production_year IS NOT NULL) 
            THEN 'Title Exists'
        ELSE 'Title Not in Database'
    END AS existence_status
FROM 
    aka_title m
WHERE 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.production_year DESC;

-- This query showcases the usage of semi-joins with peculiar conditions and null tests
SELECT 
    DISTINCT a.name, 
    CASE 
        WHEN EXISTS (SELECT 1 FROM cast_info ci WHERE ci.person_id = a.person_id) THEN 'Starred in Movies'
        ELSE 'Not a Star'
    END AS status
FROM 
    aka_name a
WHERE 
    NOT EXISTS (
        SELECT 1 FROM cast_info ci WHERE ci.person_id = a.person_id
    )
    AND a.name IS NOT NULL
ORDER BY 
    a.name;
