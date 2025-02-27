WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(c.movie_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(c.movie_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.id = c.movie_id
    GROUP BY 
        at.title, at.production_year
),
movies_with_keywords AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COALESCE(mk.keyword_id, NULL) AS movie_keyword_id
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keyword mk ON m.title = (SELECT mt.title FROM aka_title mt WHERE mt.production_year = m.production_year) 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    mwk.title,
    mwk.production_year,
    COALESCE(mwk.keyword, 'No Keywords') AS keywords,
    (SELECT COUNT(DISTINCT c.person_id) 
     FROM cast_info c 
     WHERE c.movie_id IN (SELECT id FROM aka_title WHERE production_year = mwk.production_year)) AS total_cast_in_year,
    SUM(CASE WHEN mwk.keyword IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mwk.production_year) AS keyword_count_per_year
FROM 
    movies_with_keywords mwk
WHERE 
    mwk.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mwk.production_year, keyword_count_per_year DESC;
