WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS actor_count,
        COALESCE(MAX(ki.keyword), 'None') AS main_keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.year_rank,
        rm.actor_count,
        rm.main_keyword,
        CASE 
            WHEN rm.actor_count > 10 THEN 'Blockbuster'
            WHEN rm.actor_count BETWEEN 5 AND 10 THEN 'Moderate'
            ELSE 'Indie'
        END AS movie_type
    FROM 
        RankedMovies rm 
    WHERE 
        rm.year_rank <= 5
),
MoviesWithNotes AS (
    SELECT 
        t.movie_id,
        t.title,
        t.production_year,
        t.movie_type,
        mi.info AS additional_note
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Trivia')
)
SELECT 
    mn.movie_id,
    mn.title,
    mn.production_year,
    mn.movie_type,
    COALESCE(mn.additional_note, 'No Notes Available') AS additional_note,
    ARRAY_AGG(DISTINCT a.name ORDER BY a.name ASC) AS actor_names,
    CASE 
        WHEN mn.movie_type = 'Blockbuster' AND mn.additional_note IS NOT NULL AND mn.additional_note LIKE '%excellent%' THEN 'Must Watch'
        ELSE 'Watch at Your Leisure'
    END AS recommendation 
FROM 
    MoviesWithNotes mn
JOIN 
    cast_info c ON mn.movie_id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
GROUP BY 
    mn.movie_id, mn.title, mn.production_year, mn.movie_type, mn.additional_note
ORDER BY 
    mn.production_year DESC, mn.movie_type DESC, mn.title;
