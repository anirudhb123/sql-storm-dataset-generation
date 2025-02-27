
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, ak.name, ak.id
),
actor_info AS (
    SELECT 
        ai.person_id,
        ai.info AS actor_bio,
        ak.name AS actor_name
    FROM 
        person_info ai
    JOIN 
        aka_name ak ON ai.person_id = ak.person_id
    WHERE 
        ai.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
),
movie_actor_data AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        ai.actor_bio
    FROM 
        movie_details md
    JOIN 
        actor_info ai ON md.actor_id = ai.person_id
)
SELECT 
    mad.movie_title,
    mad.production_year,
    mad.actor_name,
    mad.actor_bio,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords
FROM 
    movie_actor_data mad
LEFT JOIN 
    movie_keyword mk ON mad.movie_title = (SELECT title FROM aka_title WHERE title = mad.movie_title LIMIT 1)
GROUP BY 
    mad.movie_title, mad.production_year, mad.actor_name, mad.actor_bio
ORDER BY 
    mad.production_year DESC, mad.actor_name;
