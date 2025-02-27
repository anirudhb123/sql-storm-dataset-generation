WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
unique_titles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    ut.title,
    ut.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT ak.name), 'No actors') AS actor_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS genre
FROM 
    unique_titles ut
LEFT JOIN 
    cast_info c ON ut.title_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON ut.title_id = mk.movie_id
LEFT JOIN 
    movie_info mi ON ut.title_id = mi.movie_id
GROUP BY 
    ut.title_id, ut.title, ut.production_year
ORDER BY 
    ut.production_year DESC, keyword_count DESC
LIMIT 10;
