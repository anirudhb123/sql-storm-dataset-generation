WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY k.keyword ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredTitles AS (
    SELECT
        rt.title,
        rt.production_year,
        rt.keyword
    FROM 
        RankedTitles rt
    WHERE 
        rt.rn <= 3
),
PersonRoleCounts AS (
    SELECT 
        ci.role_id,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
)
SELECT 
    a.name AS actor_name,
    ft.title AS movie_title,
    ft.production_year,
    c.kind AS comp_cast_type,
    pr.role_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    FilteredTitles ft ON ci.movie_id = ft.title
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    comp_cast_type c ON mc.company_type_id = c.id
JOIN 
    PersonRoleCounts pr ON ci.role_id = pr.role_id
WHERE 
    ft.keyword LIKE '%Action%'
ORDER BY 
    ft.production_year DESC, 
    a.name;
