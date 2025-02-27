WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actors,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS companies,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
benchmark_info AS (
    SELECT 
        md.movie_title,
        md.production_year,
        LENGTH(md.actors) AS actor_count,
        LENGTH(md.companies) AS company_count,
        LENGTH(md.keywords) AS keyword_count
    FROM 
        movie_details md
)
SELECT 
    production_year,
    AVG(actor_count) AS avg_actors,
    AVG(company_count) AS avg_companies,
    AVG(keyword_count) AS avg_keywords
FROM 
    benchmark_info
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
