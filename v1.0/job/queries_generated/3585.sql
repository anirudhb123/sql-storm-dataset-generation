WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        t.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name t ON c.person_id = t.person_id
    WHERE 
        a.production_year >= 2000
),
movies_with_keywords AS (
    SELECT 
        r.movie_title,
        r.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        ranked_movies r
    LEFT JOIN 
        movie_keyword mk ON r.movie_title = (SELECT title FROM aka_title WHERE id = r.movie_title LIMIT 1)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        r.movie_title, r.production_year
),
movies_info AS (
    SELECT 
        m.movie_title,
        COALESCE(m.keywords, 'No keywords available') AS keywords,
        info.info AS additional_info
    FROM 
        movies_with_keywords m
    LEFT JOIN 
        movie_info mi ON m.movie_title = (SELECT title FROM aka_title WHERE id = mi.movie_id LIMIT 1)
    LEFT JOIN 
        info_type info ON mi.info_type_id = info.id
)
SELECT 
    movie_title,
    production_year,
    keywords,
    CASE 
        WHEN additional_info IS NULL THEN 'No additional information'
        ELSE additional_info
    END AS additional_info
FROM 
    movies_info
WHERE 
    production_year IN (SELECT DISTINCT production_year FROM movie_info WHERE info_type_id = 2)
ORDER BY 
    production_year DESC, movie_title;
