WITH movie_data AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT an.name ORDER BY an.name SEPARATOR ', ') AS cast_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
), 
ranked_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.cast_names,
        md.keywords,
        md.companies,
        RANK() OVER (ORDER BY md.production_year DESC) AS year_rank
    FROM 
        movie_data md
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_names,
    rm.keywords,
    rm.companies,
    rm.year_rank
FROM 
    ranked_movies rm
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC;
