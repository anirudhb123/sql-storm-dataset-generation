
WITH movie_cast AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        rc.role AS character_role,
        a.id AS movie_id
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
        AND ak.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
actor_info AS (
    SELECT 
        pi.person_id,
        STRING_AGG(pi.info, ', ') AS additional_info
    FROM 
        person_info pi
    GROUP BY 
        pi.person_id
)
SELECT 
    mc.movie_title,
    mc.production_year,
    mc.actor_name,
    mc.character_role,
    mk.keywords,
    ai.additional_info
FROM 
    movie_cast mc
LEFT JOIN 
    movie_keywords mk ON mc.movie_id = mk.movie_id
LEFT JOIN 
    actor_info ai ON mc.actor_id = ai.person_id
WHERE 
    mk.keywords IS NOT NULL
ORDER BY 
    mc.production_year DESC, mc.actor_name;
