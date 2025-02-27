WITH ranked_movies AS (
    SELECT 
        at.title AS movie_title, 
        at.production_year, 
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON ci.movie_id = at.id
    GROUP BY 
        at.id, at.title, at.production_year
), 
people_info AS (
    SELECT 
        an.name AS actor_name, 
        an.person_id, 
        pi.info AS actor_info
    FROM 
        aka_name an
    JOIN 
        person_info pi ON pi.person_id = an.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
), 
movies_with_keywords AS (
    SELECT 
        at.title AS movie_title,
        mkw.keyword
    FROM 
        aka_title at
    JOIN 
        movie_keyword mkw ON mkw.movie_id = at.id
)

SELECT 
    rm.movie_title, 
    rm.production_year, 
    rm.cast_count, 
    pi.actor_name, 
    pi.actor_info, 
    mkw.keyword
FROM 
    ranked_movies rm
FULL OUTER JOIN 
    people_info pi ON rm.rn = 1
LEFT JOIN 
    movies_with_keywords mkw ON mkw.movie_title = rm.movie_title
WHERE 
    rm.production_year IS NOT NULL AND 
    (pi.actor_info IS NOT NULL OR mkw.keyword IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
