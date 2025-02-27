WITH RECURSIVE Filmography AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY t.production_year DESC) AS rn
    FROM 
        cast_info AS ca
    INNER JOIN 
        aka_title AS t ON ca.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
DistinguishedMovies AS (
    SELECT 
        f.person_id,
        COUNT(DISTINCT f.movie_id) AS movie_count
    FROM 
        Filmography f
    GROUP BY 
        f.person_id
    HAVING 
        COUNT(DISTINCT f.movie_id) >= 5
),
RecentMovies AS (
    SELECT 
        f.person_id,
        f.movie_title,
        f.production_year
    FROM 
        Filmography f
    JOIN 
        DistinguishedMovies d ON f.person_id = d.person_id
    WHERE 
        f.rn <= 3
)
SELECT 
    p.id AS person_id,
    p.name AS person_name,
    STRING_AGG(DISTINCT rm.movie_title || ' (' || rm.production_year || ')', ', ') AS recent_movies
FROM 
    aka_name AS p
LEFT JOIN 
    RecentMovies AS rm ON p.person_id = rm.person_id
GROUP BY 
    p.id, p.name
HAVING 
    COUNT(rm.movie_title) > 0 OR p.id IS NULL
ORDER BY 
    COUNT(rm.movie_title) DESC, p.name;

-- This query provides a filmography summary of individuals who have acted in 
-- multiple movies, specifically focusing on those with five or more movies. 
-- It aggregates and lists the recent top three movies for each qualified individual 
-- while gracefully handling NULL entries from the aka_name table.
