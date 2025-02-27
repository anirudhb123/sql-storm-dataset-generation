WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), movie_cast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
    FROM 
        complete_cast m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id
), movie_info_with_notes AS (
    SELECT 
        m.movie_id,
        m.info,
        m.note,
        COALESCE(m.note, 'No additional notes') AS note_display
    FROM 
        movie_info m
    WHERE 
        m.info_type_id IN (
            SELECT id FROM info_type WHERE info ILIKE '%rating%'
        ) OR m.note IS NOT NULL
)
SELECT 
    r.title,
    r.production_year,
    mc.cast_count,
    mi.info AS rating_info,
    mi.note_display,
    CASE 
        WHEN mc.cast_count IS NULL THEN 'No cast available'
        ELSE 'Cast available'
    END AS cast_availability,
    COALESCE(STRING_AGG(DISTINCT c.name, ', ' ORDER BY c.name), 'No main characters') AS main_characters
FROM 
    ranked_movies r
LEFT JOIN 
    movie_cast mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    complete_cast cc ON r.movie_id = cc.movie_id
LEFT JOIN 
    aka_name c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_info_with_notes mi ON r.movie_id = mi.movie_id
WHERE 
    r.rank_per_year <= 5
GROUP BY 
    r.title, r.production_year, mc.cast_count, mi.info, mi.note_display
ORDER BY 
    r.production_year DESC, r.title ASC;
