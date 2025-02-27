WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT comp.name) AS companies,
        mi.info AS movie_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name comp ON mc.company_id = comp.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, mi.info, t.production_year
),
ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        cast_names,
        keywords,
        companies,
        movie_info,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rank
    FROM 
        movie_details
)

SELECT 
    movie_title,
    production_year,
    cast_names,
    keywords,
    companies,
    movie_info
FROM 
    ranked_movies
WHERE 
    rank <= 10;
