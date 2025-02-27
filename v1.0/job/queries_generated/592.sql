WITH top_movies AS (
    SELECT 
        a.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        a.id, t.title, t.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
), 
actor_info AS (
    SELECT 
        a.id AS actor_id, 
        ak.name AS actor_name, 
        pi.info AS birth_year
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id AND pi.info_type_id = 1
), 
movie_keywords AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title, 
    tm.production_year, 
    ai.actor_name, 
    ai.birth_year, 
    mk.keywords
FROM 
    top_movies tm
LEFT JOIN 
    complete_cast c ON tm.movie_id = c.movie_id
LEFT JOIN 
    actor_info ai ON c.subject_id = ai.actor_id
LEFT JOIN 
    movie_keywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
