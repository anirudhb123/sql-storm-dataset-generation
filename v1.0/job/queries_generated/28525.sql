WITH actor_movie_count AS (
    SELECT 
        ka.person_id,
        COUNT(DISTINCT kc.movie_id) AS movie_count,
        STRING_AGG(DISTINCT kt.title, ', ') AS movies
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title kt ON ci.movie_id = kt.movie_id
    GROUP BY 
        ka.person_id
),

genre_distribution AS (
    SELECT 
        mt.kind_id,
        COUNT(DISTINCT mt.id) AS movie_count,
        STRING_AGG(DISTINCT kt.title, ', ') AS titles
    FROM 
        title mt
    JOIN 
        aka_title kt ON mt.id = kt.movie_id
    GROUP BY 
        mt.kind_id
)

SELECT 
    a.actor_name,
    a.movie_count,
    g.genre_name,
    g.movie_count AS genre_count,
    g.titles AS genre_titles
FROM 
    actor_movie_count a
JOIN 
    (SELECT 
         k.id AS genre_id,
         k.kind AS genre_name,
         k.id AS kind_id
     FROM 
         kind_type k) g ON a.movie_count > 2 AND a.movie_count = g.movie_count
JOIN 
    (SELECT 
         m.id AS movie_id,
         m.title AS movie_title
     FROM 
         aka_title m) m ON m.movie_id IN (SELECT movie_id FROM movie_info_idx WHERE info_type_id = 1)
ORDER BY 
    a.movie_count DESC;
