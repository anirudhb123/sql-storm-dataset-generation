WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ARRAY_AGG(DISTINCT an.name) AS cast,
        ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
        ARRAY_AGG(DISTINCT cty.kind) AS company_types,
        COUNT(DISTINCT an.id) AS cast_count
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_type cty ON mc.company_type_id = cty.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
ranked_by_cast AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast,
        keywords,
        company_types,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS rank_by_cast
    FROM 
        ranked_movies
),
ranked_by_keywords AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast,
        keywords,
        company_types,
        cast_count,
        rank_by_cast,
        RANK() OVER (ORDER BY array_length(keywords, 1) DESC) AS rank_by_keywords
    FROM 
        ranked_by_cast
)
SELECT 
    movie_title,
    production_year,
    cast,
    keywords,
    company_types,
    cast_count,
    rank_by_cast,
    rank_by_keywords
FROM 
    ranked_by_keywords
WHERE 
    rank_by_cast <= 10 AND rank_by_keywords <= 10
ORDER BY 
    rank_by_cast, rank_by_keywords;
