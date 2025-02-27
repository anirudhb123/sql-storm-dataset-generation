WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        co.name AS company_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, co.name
),
PersonWithRoles AS (
    SELECT 
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.name
)
SELECT 
    rt.title,
    rt.production_year,
    rt.company_name,
    rt.keywords,
    pwr.actor_name,
    pwr.movie_count,
    pwr.roles
FROM 
    RankedTitles rt
JOIN 
    cast_info ci ON rt.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    PersonWithRoles pwr ON an.name = pwr.actor_name
WHERE 
    rt.rn <= 5  -- Keep only the top 5 titles per year for the final selection
ORDER BY 
    rt.production_year, rt.title;
