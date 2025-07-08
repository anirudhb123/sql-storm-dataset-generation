
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.person_id, 
        ak.name AS actor_name, 
        ct.kind AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.id) AS actor_rank
    FROM 
        cast_info a
    JOIN 
        aka_name ak ON a.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON a.person_role_id = ct.id
    WHERE 
        ak.name IS NOT NULL
),
movie_details AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title mt 
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title
),
unique_movies AS (
    SELECT 
        md.movie_id, 
        md.movie_title,
        COUNT(DISTINCT ah.actor_name) AS unique_actor_count,
        COALESCE(STRING_AGG(DISTINCT ah.actor_name, ', '), 'No Actors') AS top_actors
    FROM 
        movie_details md
    LEFT JOIN 
        actor_hierarchy ah ON md.movie_id = (SELECT mc.movie_id FROM complete_cast mc WHERE mc.subject_id = ah.person_id)
    GROUP BY 
        md.movie_id, md.movie_title
)
SELECT 
    um.movie_id, 
    um.movie_title, 
    um.unique_actor_count,
    um.top_actors,
    CASE 
        WHEN um.unique_actor_count > 10 THEN 'Blockbuster'
        WHEN um.unique_actor_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Indie'
    END AS movie_category
FROM 
    unique_movies um
ORDER BY 
    um.unique_actor_count DESC NULLS LAST,
    um.movie_title ASC
LIMIT 100;
