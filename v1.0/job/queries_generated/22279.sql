WITH RECURSIVE DirectedMovies AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        c.name AS director,
        0 AS depth
    FROM aka_name c
    JOIN cast_info ci ON c.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.movie_id
    JOIN title m ON t.id = m.id
    WHERE c.name LIKE '%Christopher Nolan%'
    AND ci.person_role_id IN (
        SELECT id FROM role_type WHERE role IN ('director', 'co-director')
    )
    
    UNION ALL

    SELECT 
        mm.id AS movie_id,
        tt.title,
        c.name AS director,
        depth + 1
    FROM DirectedMovies d
    JOIN movie_link ml ON d.movie_id = ml.movie_id
    JOIN title tt ON ml.linked_movie_id = tt.id
    JOIN aka_name c ON d.director = c.name
    JOIN aka_title t ON tt.id = t.id
    JOIN cast_info ci ON c.person_id = ci.person_id
    WHERE ci.person_role_id IN (
        SELECT id FROM role_type WHERE role IN ('director', 'co-director')
    )
)

SELECT 
    d.movie_id,
    d.title AS original_title,
    COUNT(*) AS related_movies_count,
    STRING_AGG(DISTINCT c.name, ', ') AS directors,
    AVG(CASE 
        WHEN CAST(m.production_year AS integer) < 2000 THEN 1 
        ELSE NULL 
    END) AS avg_classic_movie_years,
    MAX(CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year' 
        ELSE NULL 
    END) AS unknown_year_movies
FROM DirectedMovies d
LEFT JOIN movie_info m ON d.movie_id = m.movie_id
LEFT JOIN aka_name c ON d.director = c.name
GROUP BY d.movie_id, d.title
HAVING COUNT(DISTINCT c.id) > 1
ORDER BY related_movies_count DESC, d.movie_id
LIMIT 10;

-- Note: This query collects related movies directed by the same director(s),
-- builds a recursive structure to gather all of their linked movies (remakes, spin-offs),
-- tallies directors, averages out movie years, and includes corner cases for NULL values in production year.
