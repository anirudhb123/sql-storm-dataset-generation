WITH TopMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        movie_info mi ON m.id = mi.movie_id
    JOIN 
        cast_info c ON m.id = c.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Duration')
        AND m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
TopActors AS (
    SELECT 
        nk.name AS actor_name,
        COUNT(c.id) AS movie_count
    FROM 
        aka_name nk
    JOIN 
        cast_info c ON nk.person_id = c.person_id
    JOIN 
        TopMovies tm ON c.movie_id = tm.movie_id
    GROUP BY 
        nk.name
    ORDER BY 
        movie_count DESC
    LIMIT 5
)
SELECT 
    tm.title AS movie_title,
    tm.production_year,
    ta.actor_name,
    ta.movie_count
FROM 
    TopMovies tm
JOIN 
    TopActors ta ON EXISTS (
        SELECT 1 
        FROM cast_info c 
        WHERE c.movie_id = tm.movie_id 
        AND c.person_id = (SELECT id FROM aka_name WHERE name = ta.actor_name LIMIT 1)
    )
ORDER BY 
    tm.cast_count DESC, 
    ta.movie_count DESC;
