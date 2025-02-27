WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        a.name AS actor_name,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS c ON a.person_id = c.person_id
    WHERE 
        a.name LIKE 'A%' -- To limit to actors whose names start with 'A'
), 

movie_info_summary AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(MAX(i.info), 'No info') AS info_summary,
        COUNT(DISTINCT a.actor_id) AS total_actors
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info AS i ON m.id = i.movie_id
    LEFT JOIN 
        cast_info AS c ON m.id = c.movie_id
    LEFT JOIN 
        actor_hierarchy AS a ON c.person_id = a.person_id 
    GROUP BY 
        m.id, m.title
), 

high_rated_movies AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        ROW_NUMBER() OVER (ORDER BY m.total_actors DESC) AS movie_rank
    FROM 
        movie_info_summary m
    WHERE 
        m.total_actors > 5 AND m.keywords IS NOT NULL
    HAVING 
        COUNT(DISTINCT m.total_actors) FILTER (WHERE m.movie_title ILIKE '%action%') > 2
), 

casting_summary AS (
    SELECT 
        a.actor_id,
        a.actor_name,
        h.movie_title,
        h.movie_rank
    FROM 
        actor_hierarchy a
    INNER JOIN 
        high_rated_movies h ON a.movie_id = h.movie_id
)

SELECT 
    c.actor_name,
    c.movie_title,
    c.movie_rank,
    UNIQUE_COUNT(c.actor_name) OVER () AS unique_actor_count,
    COALESCE(c.movie_title, 'Unknown Movie') AS final_movie_title
FROM 
    casting_summary c
WHERE 
    c.movie_rank <= 10
ORDER BY 
    c.movie_rank ASC;
