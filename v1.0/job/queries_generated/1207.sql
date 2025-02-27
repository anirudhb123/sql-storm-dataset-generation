WITH ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id
),
top_ranked_movies AS (
    SELECT 
        title, 
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
)
SELECT 
    t.title AS movie_title,
    COALESCE(cn.name, 'Unknown Company') AS production_company,
    y.year,
    MAX(g.name) AS genre_name,
    COALESCE(SUM(mi.info_type_id = 1), 0) AS total_reviews,
    CASE 
        WHEN AVG(mi.info_type_id) IS NULL THEN 'No Ratings'
        ELSE CAST(AVG(mi.info_type_id) AS VARCHAR)
    END AS average_rating
FROM 
    top_ranked_movies t
LEFT JOIN 
    movie_companies mc ON t.title = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.production_year = mi.movie_id
LEFT JOIN 
    keyword k ON k.id = mi.movie_id
LEFT JOIN 
    kind_type g ON k.id = g.id
CROSS JOIN 
    (SELECT DISTINCT production_year AS year FROM aka_title) y
WHERE 
    mc.note IS NULL 
GROUP BY 
    t.title, cn.name, y.year
HAVING 
    AVG(mi.info_type_id) > 3
ORDER BY 
    t.production_year DESC, cast_count DESC;
