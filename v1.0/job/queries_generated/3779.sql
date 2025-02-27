WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
), 
highest_cast_movies AS (
    SELECT 
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        rank = 1
), 
movie_details AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(i.info, 'No Info Available') AS information,
        GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords
    FROM 
        highest_cast_movies m
    LEFT JOIN 
        movie_info i ON m.title = i.info
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.information,
    md.keywords,
    COALESCE(cn.name, 'Unknown Company') AS production_company
FROM 
    movie_details md
LEFT JOIN 
    movie_companies mc ON md.title = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    md.production_year BETWEEN 2000 AND 2020
    AND (md.keywords LIKE '%action%' OR md.keywords IS NULL)
ORDER BY 
    md.production_year DESC, 
    md.title;
