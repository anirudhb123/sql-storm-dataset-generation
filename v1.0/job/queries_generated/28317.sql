WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id, 
        t.title AS title, 
        t.production_year, 
        t.kind_id, 
        1 AS level
    FROM title t
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS title_id,
        mt.title AS title,
        mt.production_year,
        mt.kind_id,
        th.level + 1 AS level
    FROM title_hierarchy th
    JOIN movie_link ml ON th.title_id = ml.movie_id
    JOIN title mt ON ml.linked_movie_id = mt.id
    WHERE ml.link_type_id = (
        SELECT id FROM link_type WHERE link = 'sequel') 
),

combined_cast AS (
    SELECT 
        ak.id AS aka_id,
        ak.name AS actor_name,
        co.name AS company_name,
        ti.title AS movie_title,
        tc.title AS company_title,
        ti.production_year,
        r.role AS role,
        COUNT(*) OVER (PARTITION BY ak.name ORDER BY ti.production_year) AS role_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN title ti ON ci.movie_id = ti.id
    JOIN movie_companies mc ON ti.id = mc.movie_id
    JOIN company_name co ON mc.company_id = co.id
    JOIN role_type r ON ci.role_id = r.id
    LEFT JOIN title_hierarchy th ON th.title_id = ti.id
    LEFT JOIN title tc ON tc.id = th.title_id AND th.level = 1
    WHERE ti.production_year IS NOT NULL
    AND ak.name IS NOT NULL
),

final_output AS (
    SELECT 
        bc.actor_name,
        COUNT(DISTINCT bc.movie_title) AS num_movies,
        COUNT(DISTINCT bc.company_name) AS num_companies,
        AVG(bc.role_count) AS avg_role_count
    FROM combined_cast bc
    GROUP BY bc.actor_name
)

SELECT 
    actor_name, 
    num_movies, 
    num_companies, 
    avg_role_count 
FROM final_output
WHERE num_movies > 5
ORDER BY num_movies DESC;
