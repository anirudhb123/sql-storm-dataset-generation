WITH movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
top_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mkc.keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword_counts mkc ON m.id = mkc.movie_id
    WHERE 
        m.production_year >= 2000
    ORDER BY 
        mkc.keyword_count DESC
    LIMIT 10
),
actor_movies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    WHERE 
        c.movie_id IN (SELECT movie_id FROM top_movies)
    GROUP BY 
        c.movie_id, a.name
),
actor_details AS (
    SELECT 
        am.movie_id,
        am.actor_name,
        p.info AS actor_bio
    FROM 
        actor_movies am
    LEFT JOIN 
        person_info p ON p.person_id = (SELECT id FROM aka_name WHERE name = am.actor_name LIMIT 1)
)
SELECT 
    tm.title,
    tm.production_year,
    ad.actor_name,
    ad.actor_bio,
    tm.keyword_count
FROM 
    top_movies tm
LEFT JOIN 
    actor_details ad ON tm.movie_id = ad.movie_id
ORDER BY 
    tm.keyword_count DESC, ad.actor_name;
