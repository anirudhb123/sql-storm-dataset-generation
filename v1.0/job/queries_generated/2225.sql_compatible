
WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        at.id, at.title, at.production_year
), movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT
    ak.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    mk.keywords,
    CASE 
        WHEN COUNT(ci.person_id) = 0 THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    ranked_movies rm
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rn <= 5 
    AND rm.production_year >= 2000
GROUP BY 
    ak.name, rm.title, rm.production_year, mk.keywords
ORDER BY 
    rm.production_year DESC, COUNT(ci.person_id) DESC;
