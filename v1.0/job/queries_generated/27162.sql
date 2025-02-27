WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS role_ids,
        GROUP_CONCAT(DISTINCT a.name) AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        cn.country_code = 'USA'
        AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
)

SELECT 
    md.movie_title,
    md.production_year,
    md.role_ids,
    md.actor_names,
    md.keyword_count
FROM 
    movie_details md
WHERE 
    md.keyword_count > 5
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC
LIMIT 100;
