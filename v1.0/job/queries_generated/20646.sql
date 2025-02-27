WITH RecursiveCTE AS (
    SELECT 
        a.id AS aka_id, 
        a.name AS aka_name, 
        t.title AS movie_title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.id) AS rn
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE t.production_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT c.person_id) AS total_cast, 
        COUNT(DISTINCT k.keyword) AS total_keywords
    FROM movie_info m
    LEFT JOIN movie_keyword k ON m.movie_id = k.movie_id
    LEFT JOIN cast_info c ON m.movie_id = c.movie_id
    GROUP BY m.movie_id
),
Filmography AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        COUNT(cc.subject_id) AS complete_cast_count
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN title t ON c.movie_id = t.id
    LEFT JOIN complete_cast cc ON cc.movie_id = t.id AND cc.subject_id = a.id
    GROUP BY a.id, a.name, t.title, t.production_year
),
NullHandling AS (
    SELECT 
        t.title AS movie_title, 
        COALESCE(ROUND(AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) * 100, 2), 0) AS cast_note_present_percentage
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.title
)
SELECT 
    r.rn, 
    r.aka_name, 
    r.movie_title, 
    r.production_year, 
    m.total_cast, 
    m.total_keywords, 
    f.complete_cast_count,
    n.movie_title AS null_movie_title,
    nh.cast_note_present_percentage
FROM RecursiveCTE r
JOIN MovieStats m ON r.aka_id = m.movie_id
JOIN Filmography f ON r.aka_id = f.aka_id
CROSS JOIN NullHandling nh
WHERE r.production_year > 2000
    AND m.total_cast > 5 
    OR f.complete_cast_count IS NULL
ORDER BY r.production_year DESC, m.total_keywords DESC
LIMIT 100;

This SQL query highlights intricate constructs like CTEs, outer joins, window functions, and logic for handling NULL values. The query effectively gathers statistics regarding movies and the actors associated with them while employing both inner joins and outer joins to fetch detailed movie and actor records. In addition, it demonstrates handling of cases where NULL values can affect average calculations, providing an additional layer of robustness to the dataset being analyzed.
