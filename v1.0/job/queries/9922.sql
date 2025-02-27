
WITH RankedFilms AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT c.note, ', ') AS cast_notes,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopFilms AS (
    SELECT 
        rf.title_id, 
        rf.title, 
        rf.production_year, 
        rf.cast_count, 
        rf.cast_notes, 
        rf.keywords,
        RANK() OVER (ORDER BY rf.cast_count DESC) AS rank
    FROM 
        RankedFilms rf
)
SELECT 
    tf.title,
    tf.production_year,
    tf.cast_count,
    tf.cast_notes,
    tf.keywords
FROM 
    TopFilms tf
WHERE 
    tf.rank <= 10 
ORDER BY 
    tf.cast_count DESC;
