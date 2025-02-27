WITH MovieCredits AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order,
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT actor_name) AS actor_count,
        MAX(role_rank) AS max_role_rank
    FROM 
        MovieCredits
    WHERE 
        actor_name IS NOT NULL
    GROUP BY 
        movie_title, production_year
    HAVING 
        COUNT(DISTINCT actor_name) > 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.actor_count,
    CASE 
        WHEN tm.max_role_rank = 1 THEN 'Lead'
        ELSE 'Supporting'
    END AS role_type,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
     AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')) AS genre_count
FROM 
    TopMovies tm
JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title LIMIT 1)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    k.keyword IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.actor_count DESC;
