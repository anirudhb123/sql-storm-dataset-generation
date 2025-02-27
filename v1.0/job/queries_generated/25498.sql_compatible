
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_casts,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        ARRAY_AGG(DISTINCT k.keyword) AS movie_keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title m
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'IMDb Rating')
        AND mi.info IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
selected_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_casts,
        rm.actor_names,
        rm.movie_keywords
    FROM
        ranked_movies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    sm.movie_id,
    sm.title,
    sm.production_year,
    sm.total_casts,
    STRING_AGG(DISTINCT name.name, ', ') AS top_actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    selected_movies sm
JOIN 
    cast_info c ON sm.movie_id = c.movie_id
JOIN 
    aka_name name ON c.person_id = name.person_id
LEFT JOIN 
    movie_keyword mk ON sm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    sm.movie_id, sm.title, sm.production_year, sm.total_casts
ORDER BY 
    sm.total_casts DESC;
