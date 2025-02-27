WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY mt.production_year DESC, mt.title) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
)
SELECT 
    rank,
    movie_id,
    title,
    production_year,
    aka_names,
    keywords,
    company_count,
    cast_count
FROM 
    ranked_movies
WHERE 
    company_count > 5 AND cast_count > 10
ORDER BY 
    rank;
