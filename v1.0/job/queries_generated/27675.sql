WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.kind_id = 1 -- Assuming 1 represents feature films
    GROUP BY 
        m.id, m.title, m.production_year
),

top_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        actor_names
    FROM 
        ranked_movies
    WHERE 
        rank_by_cast <= 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.actor_names,
    m_info.info AS extra_info
FROM 
    top_movies tm
LEFT JOIN 
    movie_info m_info ON tm.movie_id = m_info.movie_id AND m_info.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;

