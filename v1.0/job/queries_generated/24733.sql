WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(mo.linked_movie_id, 0) AS linked_id,
        mo.link_type_id,
        1 AS level
    FROM 
        title m
    LEFT JOIN 
        movie_link mo ON m.id = mo.movie_id
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        COALESCE(mo.linked_movie_id, 0) AS linked_id,
        mo.link_type_id,
        mh.level + 1
    FROM 
        title m
    JOIN 
        movie_link mo ON m.id = mo.movie_id
    JOIN 
        movie_hierarchy mh ON mo.linked_movie_id = mh.movie_id
    WHERE 
        mh.level < 5
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(mk.keyword_id) DESC) AS rnk
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title
),
actor_movie_info AS (
    SELECT 
        ca.movie_id,
        a.name AS actor_name,
        a.imdb_index,
        COUNT(DISTINCT ci.person_role_id) AS roles_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        ca.movie_id, a.name, a.imdb_index
)
SELECT 
    tm.movie_title,
    COALESCE(ai.actor_name, 'No Actor') AS lead_actor,
    tm.keyword_count,
    CASE 
        WHEN tm.keyword_count > 10 THEN 'Popular'
        WHEN tm.keyword_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Rarely Mentioned'
    END AS popularity_category,
    COALESCE(ai.roles_count, 0) AS roles_count
FROM 
    top_movies tm
LEFT JOIN 
    actor_movie_info ai ON tm.movie_id = ai.movie_id
WHERE 
    (tm.keyword_count > 0 OR ai.actor_name IS NOT NULL)
ORDER BY 
    tm.rnk, popularity_category DESC
LIMIT 50;
