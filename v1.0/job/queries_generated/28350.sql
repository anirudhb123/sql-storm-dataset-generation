WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.note AS cast_note,
        ak.name AS actor_name,
        ak.id AS actor_id,
        kc.keyword AS movie_keyword,
        mk.note AS movie_note
    FROM 
        aka_title ak
    JOIN 
        cast_info ci ON ak.movie_id = ci.movie_id
    JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        keyword kc ON t.id = (
            SELECT movie_id 
            FROM movie_keyword 
            WHERE keyword_id = kc.id
            LIMIT 1  -- Limit ensures we only fetch one keyword per movie
        )
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_info_idx mk ON t.id = mk.movie_id 
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND (ak.name LIKE 'Robert%' OR ak.name LIKE 'Chris%')  -- Filter for specific actor names
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
),
summary AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT actor_id) AS total_actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cast_note, '; ') AS cast_notes,
        STRING_AGG(DISTINCT movie_note, '; ') AS movie_notes
    FROM 
        movie_details
    GROUP BY 
        movie_title, production_year
)

SELECT 
    movie_title,
    production_year,
    total_actors,
    keywords,
    cast_notes,
    movie_notes
FROM 
    summary
ORDER BY 
    production_year DESC, total_actors DESC;
