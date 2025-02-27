WITH movie_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.person_id
),
highest_movie_counts AS (
    SELECT 
        mc.person_id, 
        mc.movie_count,
        a.name
    FROM 
        movie_counts mc
    JOIN 
        aka_name a ON mc.person_id = a.person_id
    WHERE 
        mc.movie_count = (SELECT MAX(movie_count) FROM movie_counts)
),
top_movies AS (
    SELECT 
        m.id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY mk.keyword ORDER BY m.production_year DESC) AS rn
    FROM 
        movie_keyword mk
    JOIN 
        title m ON mk.movie_id = m.id
    ORDER BY 
        mk.keyword
)
SELECT 
    hmc.name AS actor_name,
    hmc.movie_count AS total_movies,
    tm.title AS top_movie_title,
    tm.production_year AS top_movie_year,
    k.keyword AS associated_keyword
FROM 
    highest_movie_counts hmc
JOIN 
    top_movies tm ON hmc.person_id IN 
        (SELECT DISTINCT c.person_id 
         FROM cast_info c 
         JOIN movie_keyword mk ON c.movie_id = mk.movie_id 
         WHERE mk.keyword IN 
               (SELECT DISTINCT keyword FROM keyword))
JOIN 
    movie_keyword mk ON mk.movie_id = tm.id 
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rn = 1
ORDER BY 
    total_movies DESC, 
    actor_name ASC;
