WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS company_name,
        k.keyword AS movie_keyword,
        p.info AS person_info
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    WHERE 
        t.production_year >= 2000 
        AND k.keyword LIKE '%action%'
),
company_count AS (
    SELECT 
        company_name,
        COUNT(*) AS num_movies
    FROM 
        movie_data
    GROUP BY 
        company_name
)
SELECT 
    m.title,
    m.production_year,
    m.actor_name,
    cc.num_movies
FROM 
    movie_data m
JOIN 
    company_count cc ON m.company_name = cc.company_name
ORDER BY 
    cc.num_movies DESC, 
    m.production_year ASC
LIMIT 10;
