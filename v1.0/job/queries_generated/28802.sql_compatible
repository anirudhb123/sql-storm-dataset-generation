
WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS alias_names,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        aka_name an ON cc.subject_id = an.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
filtered_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        alias_names, 
        company_names, 
        keywords,
        rn
    FROM 
        ranked_movies
    WHERE 
        rn <= 5 
)
SELECT 
    production_year,
    COUNT(*) AS total_movies,
    STRING_AGG(movie_title, '; ') AS movie_titles,
    STRING_AGG(alias_names, '; ') AS all_alias_names,
    STRING_AGG(company_names, '; ') AS all_company_names,
    STRING_AGG(keywords, '; ') AS all_keywords
FROM 
    filtered_movies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC
LIMIT 10;
