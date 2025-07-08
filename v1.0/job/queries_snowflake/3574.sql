WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS cast_with_note_rate
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_with_note_rate,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, production_year DESC) AS rank
    FROM 
        MovieDetails
    WHERE 
        total_cast > 5
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    COALESCE(NULLIF(tm.cast_with_note_rate, 0), 0) AS cast_with_note_rate,
    n.name AS lead_actor
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info c ON tm.movie_id = c.movie_id
LEFT JOIN 
    aka_name n ON c.person_id = n.person_id
WHERE 
    tm.rank <= 10 AND 
    c.nr_order = 1
ORDER BY 
    tm.total_cast DESC, 
    tm.production_year DESC;
