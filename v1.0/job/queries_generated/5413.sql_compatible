
WITH MovieData AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year > 2000
    GROUP BY 
        mt.title, mt.production_year, ak.name, ak.id
    ORDER BY 
        mt.production_year DESC, ak.name
)

SELECT 
    DISTINCT movie_title, 
    production_year, 
    actor_name, 
    production_companies,
    keywords
FROM 
    MovieData
WHERE 
    production_companies > 2
ORDER BY 
    production_year DESC, actor_name;
