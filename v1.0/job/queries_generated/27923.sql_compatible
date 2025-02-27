
WITH movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(a.name, ', ' ORDER BY c.nr_order) AS cast_names,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.cast_names,
        k.keywords,
        COALESCE(m.note, 'No notes available') AS movie_note,
        c.total_cast
    FROM 
        title t
    LEFT JOIN 
        movie_cast c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keywords k ON t.id = k.movie_id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Note' LIMIT 1)
    WHERE 
        t.production_year >= 2000
)
SELECT 
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords,
    md.movie_note
FROM 
    movie_details md
WHERE 
    md.total_cast > 5
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 10;
