
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        pt.role,
        COALESCE(rnk.rank, 0) AS year_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type pt ON c.role_id = pt.id
    LEFT JOIN 
        ranked_titles rnk ON c.movie_id = rnk.title_id
)
SELECT 
    mv.title,
    mv.production_year,
    STRING_AGG(DISTINCT cd.actor_name, ', ') AS cast_names,
    ct.kind AS company_type,
    COUNT(k.keyword) AS keyword_count
FROM 
    ranked_titles mv
JOIN 
    complete_cast cc ON mv.title_id = cc.movie_id
JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON mv.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    cast_details cd ON mv.title_id = cd.movie_id
WHERE 
    mv.rank <= 10
GROUP BY 
    mv.title, mv.production_year, ct.kind
ORDER BY 
    mv.production_year DESC;
