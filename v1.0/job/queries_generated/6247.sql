WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        GROUP_CONCAT(DISTINCT c.name) AS actors,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.id = ci.id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
final_output AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.movie_id ORDER BY RAND()) AS rn
    FROM 
        movie_details md
)
SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    actors,
    companies
FROM 
    final_output
WHERE 
    rn <= 5
ORDER BY 
    production_year DESC, title;
