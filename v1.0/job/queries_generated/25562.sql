WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.id) AS cast_ids,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT com.name) AS companies,
        GROUP_CONCAT(DISTINCT p.info) AS person_info
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name com ON mc.company_id = com.id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
ranked_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        aka_names,
        keywords,
        companies,
        person_info,
        RANK() OVER (ORDER BY production_year DESC) AS year_rank
    FROM 
        movie_details
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    aka_names,
    keywords,
    companies,
    person_info,
    year_rank
FROM 
    ranked_movies
WHERE 
    year_rank <= 10
ORDER BY 
    production_year DESC, movie_title;

This query aggregates various details from the `title`, `cast_info`, `aka_name`, `movie_keyword`, `keyword`, `movie_companies`, `company_name`, and `person_info` tables to get insights into movies produced between 2000 and 2023. The result includes the movie title, production year, any aliases, keywords, associated companies, and relevant person information, ranked by production year. The final output only shows the top 10 recent movies.
