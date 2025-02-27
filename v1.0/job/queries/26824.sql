WITH movie_aggregates AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
actor_aggregates AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT mt.title, ', ') AS movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title mt ON ci.movie_id = mt.id
    GROUP BY 
        ak.person_id, ak.name
)
SELECT 
    ma.movie_id,
    ma.title,
    ma.production_year,
    ma.total_companies,
    ma.company_names,
    ma.total_keywords,
    ma.keywords,
    aa.person_id,
    aa.name AS actor_name,
    aa.total_movies,
    aa.movies
FROM 
    movie_aggregates ma
JOIN 
    cast_info ci ON ma.movie_id = ci.movie_id
JOIN 
    actor_aggregates aa ON ci.person_id = aa.person_id
ORDER BY 
    ma.production_year DESC, ma.title;
