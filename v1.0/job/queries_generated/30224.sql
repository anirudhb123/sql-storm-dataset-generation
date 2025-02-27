WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
)
SELECT 
    m.title AS Movie_Title,
    m.production_year AS Release_Year,
    COALESCE(cast_array.actors, 'No Cast Available') AS Actors,
    COUNT(DISTINCT k.keyword) AS Total_Keywords,
    AVG(rate.user_score) AS Average_User_Score
FROM 
    movie_hierarchy m
LEFT JOIN (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
) AS cast_array ON m.movie_id = cast_array.movie_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN keyword k ON mk.keyword_id = k.id
LEFT JOIN LATERAL (
    SELECT 
        mv.imdb_id AS movie_id, 
        mv.user_score 
    FROM 
        movie_info mv 
    WHERE 
        mv.info_type_id = (SELECT id FROM info_type WHERE info = 'User Rating')
        AND mv.movie_id = m.movie_id
) AS rate ON TRUE
WHERE 
    m.level < 3 -- limiting hierarchy level to 2 for better performance
GROUP BY 
    m.movie_id, m.title, m.production_year, cast_array.actors
ORDER BY 
    m.production_year DESC, COUNT(DISTINCT k.keyword) DESC;
