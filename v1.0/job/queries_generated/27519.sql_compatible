
WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(DISTINCT ac.name, ', ') AS actors,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        aka_name ac ON cc.subject_id = ac.person_id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY 
        mt.title, mt.production_year
), year_benchmark AS (
    SELECT 
        production_year,
        COUNT(*) AS movie_count,
        AVG(LENGTH(movie_title)) AS avg_title_length,
        AVG(LENGTH(actors)) AS avg_actors_length,
        AVG(LENGTH(companies)) AS avg_companies_length,
        AVG(LENGTH(keywords)) AS avg_keywords_length
    FROM 
        movie_details
    GROUP BY 
        production_year
)
SELECT 
    production_year,
    movie_count,
    avg_title_length,
    avg_actors_length,
    avg_companies_length,
    avg_keywords_length,
    CASE 
        WHEN movie_count > 10 THEN 'High'
        WHEN movie_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Low'
    END AS movie_count_category
FROM 
    year_benchmark
ORDER BY 
    production_year DESC;
