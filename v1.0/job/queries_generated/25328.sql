WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        GROUP_CONCAT(DISTINCT a.name) AS actors
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id
), ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.companies,
        md.actors,
        RANK() OVER (PARTITION BY md.production_year ORDER BY COUNT(DISTINCT md.actors) DESC) AS rank_order
    FROM 
        movie_details md
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.keywords, md.companies, md.actors
)
SELECT 
    rm.rank_order,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.companies,
    rm.actors
FROM 
    ranked_movies rm
WHERE 
    rm.rank_order <= 10
ORDER BY 
    rm.production_year, rm.rank_order;
