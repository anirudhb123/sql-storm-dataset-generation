WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title AS title_name,
        t.production_year,
        1 AS level
    FROM 
        title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL
    
    SELECT 
        t.id AS title_id,
        CONCAT(th.title_name, ' -> ', t.title) AS title_name,
        t.production_year,
        th.level + 1
    FROM 
        title t
    INNER JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id
)

SELECT 
    COALESCE(a.name, cn.name) AS actor_or_company,
    th.title_name,
    th.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    FIRST_VALUE(ct.kind) OVER(PARTITION BY th.title_id ORDER BY ct.id) AS first_company_type,
    CASE 
        WHEN th.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(th.production_year AS TEXT)
    END AS production_year_display
FROM 
    title_hierarchy th
LEFT JOIN 
    complete_cast cc ON th.title_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = th.title_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON th.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    COALESCE(a.name, cn.name), th.title_name, th.production_year
ORDER BY 
    th.production_year DESC, actor_or_company;
