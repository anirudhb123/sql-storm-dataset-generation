
WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
highest_ranked AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
detailed_movies AS (
    SELECT 
        hr.movie_id,
        hr.title,
        hr.production_year,
        hr.cast_count,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        highest_ranked hr
    LEFT JOIN 
        movie_keywords mk ON hr.movie_id = mk.movie_id
)
SELECT 
    dm.title,
    dm.production_year,
    dm.cast_count,
    dm.keywords,
    (SELECT COUNT(DISTINCT c.id) 
     FROM movie_companies mc 
     JOIN company_name c ON mc.company_id = c.id 
     WHERE mc.movie_id = dm.movie_id) AS company_count
FROM 
    detailed_movies dm
ORDER BY 
    dm.production_year DESC, 
    dm.cast_count DESC;
