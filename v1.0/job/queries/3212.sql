WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
DetailedActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        AVG(CASE WHEN c.note IS NULL THEN 0 ELSE 1 END) AS avg_notes
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    t.title,
    t.production_year,
    d.name AS actor_name,
    d.movie_count,
    d.avg_notes
FROM 
    TopMovies t
JOIN 
    DetailedActors d ON d.movie_count > 0
LEFT JOIN 
    movie_info mi ON t.movie_id = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'box office%')
ORDER BY 
    t.production_year DESC, d.movie_count DESC;
