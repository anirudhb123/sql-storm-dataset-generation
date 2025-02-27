WITH ranked_movies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
filtered_movies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.num_cast_members
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    f.movie_title,
    f.production_year,
    f.num_cast_members,
    COALESCE(g.genre, 'Unknown') AS genre,
    CASE 
        WHEN f.num_cast_members > 0 THEN 'Highly Casted'
        WHEN f.num_cast_members IS NULL THEN 'No Cast'
        ELSE 'Low Cast'
    END AS cast_quality
FROM 
    filtered_movies f
LEFT JOIN 
    (SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword) AS genre
     FROM 
        aka_title m
     JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
     JOIN 
        keyword k ON mk.keyword_id = k.id
     GROUP BY 
        m.movie_id) g ON f.movie_id = g.movie_id
ORDER BY 
    f.production_year DESC, 
    f.num_cast_members DESC;
