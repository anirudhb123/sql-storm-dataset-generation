
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
modern_movies AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count
    FROM 
        ranked_movies r
    WHERE 
        r.production_year >= 2000
),
highest_cast_count AS (
    SELECT 
        production_year,
        MAX(cast_count) AS max_cast
    FROM 
        modern_movies
    GROUP BY 
        production_year
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    COALESCE(num_oscars.awards, 0) AS oscars_won,
    CASE 
        WHEN COALESCE(num_oscars.awards, 0) > 0 THEN 'Award Winner'
        ELSE 'No Awards'
    END AS award_status
FROM 
    modern_movies m
LEFT JOIN 
    (SELECT 
        t.title,
        COUNT(*) AS awards
     FROM 
        movie_info mi
     JOIN 
        aka_title t ON mi.movie_id = t.id
     WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Oscar')
     GROUP BY 
        t.title) num_oscars ON m.title = num_oscars.title
WHERE 
    m.cast_count = (SELECT h.max_cast FROM highest_cast_count h WHERE h.production_year = m.production_year)
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
