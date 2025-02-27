WITH relevant_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT c.person_id) AS cast_members
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        m.id, m.title, m.production_year, k.keyword
),
actors_info AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        ai.info AS actor_info
    FROM 
        aka_name a
    JOIN 
        person_info ai ON a.person_id = ai.person_id
    WHERE 
        ai.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date')
),
movies_with_actor_info AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.movie_keyword,
        GROUP_CONCAT(DISTINCT ai.actor_name) AS actor_names,
        GROUP_CONCAT(DISTINCT ai.actor_info) AS actor_infos
    FROM 
        relevant_movies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        actors_info ai ON ci.person_id = ai.actor_id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.movie_keyword
)
SELECT
    movie_title,
    production_year,
    movie_keyword,
    actor_names,
    actor_infos
FROM 
    movies_with_actor_info
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, movie_title;
