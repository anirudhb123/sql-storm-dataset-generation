
WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT ik.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword ik ON mk.keyword_id = ik.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),

ranked_movies_with_ids AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        aka_names,
        keywords,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast
    FROM 
        ranked_movies
)

SELECT 
    r.movie_id, 
    r.movie_title, 
    r.production_year, 
    r.cast_count, 
    r.aka_names,
    r.keywords
FROM 
    ranked_movies_with_ids r
WHERE 
    r.rank_by_cast <= 10
ORDER BY 
    r.production_year, 
    r.cast_count DESC;
