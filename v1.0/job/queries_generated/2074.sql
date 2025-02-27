WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
)
SELECT 
    tm.production_year,
    STRING_AGG(tm.title, ', ') AS top_movies,
    COUNT(DISTINCT c.person_id) AS distinct_actors,
    AVG(length(a.name)) AS avg_actor_name_length
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title IN (SELECT t.title FROM aka_title t WHERE t.id = ci.movie_id)
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mi.movie_id IN (SELECT m.id FROM aka_title m WHERE m.title = tm.title)
WHERE 
    mi.info_type_id IS NULL OR mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Drama%')
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
