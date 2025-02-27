WITH RECURSIVE actor_movies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) as rn
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
top_actors AS (
    SELECT 
        person_id,
        COUNT(*) as movie_count
    FROM 
        actor_movies
    WHERE 
        rn <= 5
    GROUP BY 
        person_id
    HAVING 
        COUNT(*) > 3
),
detailed_actor_info AS (
    SELECT 
        a.name,
        tm.title,
        tm.production_year,
        ac.nr_order,
        c.kind,
        COALESCE(ci.info, 'No additional info') AS additional_info
    FROM 
        aka_name a
    JOIN 
        cast_info ac ON a.person_id = ac.person_id
    JOIN 
        aka_title tm ON ac.movie_id = tm.movie_id
    JOIN 
        comp_cast_type c ON ac.person_role_id = c.id
    LEFT JOIN 
        person_info ci ON ac.person_id = ci.person_id AND ci.info_type_id = 1
    WHERE 
        a.id IN (SELECT person_id FROM top_actors)
),
aggregate_actor_info AS (
    SELECT 
        name,
        STRING_AGG(DISTINCT title || ' (' || production_year || ')', ', ') AS movies
    FROM 
        detailed_actor_info
    GROUP BY 
        name
)
SELECT 
    ai.name,
    ai.movies,
    COALESCE(NULLIF(e.movie_count, 0), 'No Movies') AS movie_counts
FROM 
    aggregate_actor_info ai
LEFT JOIN 
    top_actors e ON ai.name IN (SELECT a.name FROM aka_name a WHERE a.person_id = e.person_id)
ORDER BY 
    ai.name;
