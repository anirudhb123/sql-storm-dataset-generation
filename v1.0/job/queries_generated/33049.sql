WITH RECURSIVE cast_hierarchy AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.role_id,
        1 AS level
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order = 1
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.role_id,
        ch.level + 1
    FROM 
        cast_info ci
    INNER JOIN 
        cast_hierarchy ch ON ci.movie_id = ch.movie_id AND ci.nr_order = ch.level + 1
),
ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY c.company_id ORDER BY t.production_year DESC) AS rank_per_company
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code = 'USA'
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    cc.keyword_count,
    ch.level,
    c.kind AS company_type
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    keyword_count cc ON at.id = cc.movie_id
LEFT JOIN 
    cast_hierarchy ch ON ci.movie_id = ch.movie_id AND ci.person_id = ch.person_id
WHERE 
    at.production_year >= 2000
    AND cc.keyword_count IS NULL
ORDER BY 
    at.production_year DESC, 
    actor_name;

