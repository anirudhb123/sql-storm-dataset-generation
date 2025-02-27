WITH actor_movie_counts AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.name
), 
movies_with_keywords AS (
    SELECT 
        mt.title,
        mt.production_year,
        k.keyword
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000
), 
actor_movie_keywords AS (
    SELECT 
        am.actor_name,
        mwk.title,
        mwk.production_year,
        mwk.keyword
    FROM 
        actor_movie_counts am
    JOIN 
        cast_info ci ON am.actor_name = (SELECT name FROM aka_name WHERE person_id = ci.person_id)
    JOIN 
        movies_with_keywords mwk ON ci.movie_id = (SELECT id FROM aka_title WHERE title = mwk.title)
)

SELECT 
    actor_movie_keywords.actor_name,
    actor_movie_keywords.title,
    actor_movie_keywords.production_year,
    STRING_AGG(actor_movie_keywords.keyword, ', ') AS keywords
FROM 
    actor_movie_keywords
GROUP BY 
    actor_movie_keywords.actor_name,
    actor_movie_keywords.title,
    actor_movie_keywords.production_year
ORDER BY 
    actor_movie_keywords.actor_name, 
    actor_movie_keywords.production_year DESC;
