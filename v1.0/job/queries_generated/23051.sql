WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT *
    FROM RankedMovies
    WHERE rank <= 5
),
CastDetails AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        t.production_year,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        a.name IS NOT NULL
)
SELECT 
    tr.movie_id,
    tr.title,
    tr.production_year,
    CAST(COALESCE(SUM(CASE WHEN c.actor_rank IS NOT NULL THEN 1 ELSE 0 END), 0) AS INTEGER) AS num_actors,
    STRING_AGG(c.actor_name, ', ') AS actors_list
FROM 
    TopRankedMovies tr
LEFT JOIN 
    CastDetails c ON tr.title = c.title AND tr.production_year = c.production_year
GROUP BY 
    tr.movie_id, tr.title, tr.production_year
ORDER BY 
    tr.production_year DESC, num_actors DESC
LIMIT 10
OFFSET 5
UNION ALL 
SELECT 
    m.movie_id, 
    t.title, 
    t.production_year, 
    COUNT(m.movie_id) AS num_movies, 
    NULL AS actors_list
FROM 
    movie_info m
JOIN 
    aka_title t ON m.movie_id = t.movie_id
WHERE 
    m.info_type_id IN (SELECT id FROM info_type WHERE info = 'box office')
GROUP BY 
    m.movie_id, t.title, t.production_year
HAVING 
    COUNT(m.movie_id) > 0
ORDER BY 
    num_movies DESC
FETCH FIRST 5 ROWS ONLY;
