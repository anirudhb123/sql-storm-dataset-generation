
WITH ranked_movies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
highly_casted AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COUNT(ci.person_id) AS total_cast
    FROM 
        ranked_movies rm
    JOIN 
        cast_info ci ON rm.title_id = ci.movie_id
    WHERE 
        rm.movie_rank <= 5
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
),
movies_with_keywords AS (
    SELECT 
        hm.title,
        hm.production_year,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        highly_casted hm
    LEFT JOIN 
        movie_keyword mk ON hm.title_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        hm.title, hm.production_year
)
SELECT 
    mwkw.title,
    mwkw.production_year,
    mwkw.keywords,
    CASE 
        WHEN mwkw.keywords IS NULL THEN 'No keywords available'
        ELSE mwkw.keywords
    END AS keywords_info
FROM 
    movies_with_keywords mwkw
ORDER BY 
    mwkw.production_year DESC,
    mwkw.title ASC;
