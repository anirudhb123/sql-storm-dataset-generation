
WITH movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        c.name AS company_name,
        STRING_AGG(DISTINCT an.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON mt.movie_id = cc.movie_id
    JOIN 
        aka_name an ON cc.subject_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year >= 2000 AND 
        mt.kind_id IN (1, 2)  
    GROUP BY 
        mt.id, mt.title, mt.production_year, c.name
), benchmark_stats AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        company_name,
        actors, 
        keywords,
        LENGTH(title) AS title_length,
        LENGTH(company_name) AS company_length,
        ARRAY_LENGTH(STRING_TO_ARRAY(actors, ', '), 1) AS actor_count,
        ARRAY_LENGTH(STRING_TO_ARRAY(keywords, ', '), 1) AS keyword_count
    FROM 
        movie_details
)

SELECT 
    *,
    CASE 
        WHEN actor_count > 100 THEN 'A Lot of Actors'
        WHEN actor_count > 50 THEN 'Moderate Actors'
        ELSE 'Few Actors'
    END AS actor_group,
    CASE 
        WHEN title_length > 30 THEN 'Long Title'
        ELSE 'Short Title'
    END AS title_category
FROM 
    benchmark_stats
ORDER BY 
    production_year DESC, 
    title_length DESC;
