WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rank_in_year
    FROM 
        aka_title m 
    WHERE 
        m.production_year IS NOT NULL
),
actor_movie_count AS (
    SELECT 
        c.person_id, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
movies_with_actors AS (
    SELECT 
        r.movie_id, 
        r.title, 
        r.production_year, 
        a.person_id, 
        a.role_id,
        COALESCE(ac.movie_count, 0) AS number_of_movies_by_actor
    FROM 
        ranked_movies r
    LEFT JOIN 
        cast_info a ON r.movie_id = a.movie_id
    LEFT JOIN 
        actor_movie_count ac ON a.person_id = ac.person_id
),
keyword_movies AS (
    SELECT 
        m.movie_id, 
        m.title, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title
)
SELECT 
    mwa.title,
    mwa.production_year,
    mwa.person_id,
    mwa.number_of_movies_by_actor,
    km.keywords
FROM 
    movies_with_actors mwa
LEFT JOIN 
    keyword_movies km ON mwa.movie_id = km.movie_id
WHERE 
    mwa.production_year = (SELECT MAX(production_year) FROM aka_title)
ORDER BY 
    mwa.number_of_movies_by_actor DESC, 
    mwa.title ASC
LIMIT 10;
