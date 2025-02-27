WITH RECURSIVE actor_hierarchy AS (
    -- Base case: Select all actors and their first level of movie roles
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        1 AS depth
    FROM 
        cast_info ci
    WHERE 
        ci.nr_order = 1
    
    UNION ALL
    
    -- Recursive case: Select actors for movies including their depth
    SELECT 
        ci.person_id, 
        ci.movie_id, 
        ah.depth + 1
    FROM 
        cast_info ci
    JOIN 
        actor_hierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ci.nr_order > ah.depth
),
movie_details AS (
    -- Select movies with their titles and production year
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_summary AS (
    -- Get keywords associated with movies
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
filtered_movies AS (
    -- Filter movies based on a certain condition (e.g., being associated with more than 5 actors)
    SELECT 
        md.movie_id, 
        md.title, 
        md.production_year, 
        md.actor_count,
        ks.keywords
    FROM 
        movie_details md
    LEFT JOIN 
        keyword_summary ks ON md.movie_id = ks.movie_id
    WHERE 
        md.actor_count > 5
),
final_results AS (
    -- Fetch detailed information, including the actor hierarchy
    SELECT 
        fm.title, 
        fm.production_year,
        CASE 
            WHEN ah.person_id IS NULL THEN 'No Main Actor'
            ELSE n.name
        END AS main_actor,
        fm.keywords
    FROM 
        filtered_movies fm
    LEFT JOIN 
        (SELECT DISTINCT ON (ah.movie_id) ah.movie_id, a.name, ah.person_id
         FROM actor_hierarchy ah
         JOIN aka_name a ON a.person_id = ah.person_id
         ORDER BY ah.movie_id, ah.depth
        ) AS ah ON fm.movie_id = ah.movie_id
    LEFT JOIN 
        aka_name n ON ah.person_id = n.person_id
)
-- Finally, select results ordered by production year and title
SELECT 
    title, 
    production_year, 
    main_actor, 
    keywords
FROM 
    final_results
ORDER BY 
    production_year DESC, 
    title ASC;
