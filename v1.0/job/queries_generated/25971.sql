WITH StringProcessing AS (
    SELECT 
        a.name AS actor_name,
        m.title AS movie_title,
        c.role_id AS role_id,
        REPLACE(a.name, ' ', '') AS actor_name_no_spaces,
        UPPER(m.title) AS movie_title_upper,
        LENGTH(m.title) AS title_length,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY m.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON c.movie_id = m.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.name IS NOT NULL AND 
        m.production_year IS NOT NULL
    GROUP BY 
        a.id, m.id, c.role_id
)
SELECT 
    actor_name,
    movie_title,
    role_id,
    actor_name_no_spaces,
    movie_title_upper,
    title_length,
    recent_movie_rank,
    STRING_AGG(DISTINCT keyword, ', ') AS all_keywords
FROM 
    StringProcessing
WHERE 
    recent_movie_rank <= 5
ORDER BY 
    recent_movie_rank, actor_name;
