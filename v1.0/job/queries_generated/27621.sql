WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        k.keyword AS keyword_name,
        ROW_NUMBER() OVER (PARTITION BY k.keyword ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    a.person_id,
    a.name AS actor_name,
    rt.title_name,
    rt.production_year,
    COUNT(DISTINCT rt.keyword_name) AS keyword_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    RankedTitles rt ON t.id = rt.title_id
WHERE 
    rt.rn = 1 -- get only the latest title for each keyword
GROUP BY 
    a.person_id, a.name, rt.title_name, rt.production_year
ORDER BY 
    keyword_count DESC, a.name;
