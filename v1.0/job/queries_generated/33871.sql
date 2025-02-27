WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title AS movie_title,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COALESCE(c.kind, 'N/A') AS company_kind,
        1 AS level
    FROM 
        aka_title AS a_title
    JOIN 
        title AS m ON a_title.movie_id = m.id
    LEFT JOIN 
        cast_info AS ci ON ci.movie_id = m.id 
    LEFT JOIN 
        aka_name AS a ON ci.person_id = a.person_id 
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_type AS c ON mc.company_type_id = c.id
    WHERE 
        m.production_year >= 2000
    UNION ALL 
    SELECT 
        mh.movie_id, 
        mh.movie_title,
        COALESCE(a.name, 'Unknown') AS actor_name,
        COALESCE(c.kind, 'N/A') AS company_kind,
        level + 1
    FROM 
        movie_hierarchy AS mh
    JOIN 
        movie_link AS ml ON ml.movie_id = mh.movie_id
    LEFT JOIN 
        title AS m ON ml.linked_movie_id = m.id
    LEFT JOIN 
        cast_info AS ci ON ci.movie_id = m.id 
    LEFT JOIN 
        aka_name AS a ON ci.person_id = a.person_id 
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = m.id
    LEFT JOIN 
        company_type AS c ON mc.company_type_id = c.id
    WHERE 
        m.production_year >= 2000
),
aggregate_movie_data AS (
    SELECT 
        movie_id,
        movie_title,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT company_kind, ', ') AS companies,
        COUNT(DISTINCT actor_name) AS actor_count,
        COUNT(DISTINCT company_kind) AS company_count
    FROM 
        movie_hierarchy
    GROUP BY 
        movie_id, movie_title
)
SELECT 
    amd.movie_title,
    amd.actor_count,
    amd.company_count,
    CASE 
        WHEN amd.actor_count > 0 AND amd.company_count > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS activity_status,
    CONCAT('Actors: ', amd.actors) AS actor_list,
    CONCAT('Companies: ', amd.companies) AS company_list
FROM 
    aggregate_movie_data AS amd
WHERE 
    amd.actor_count > 5 OR amd.company_count > 3
ORDER BY 
    amd.movie_title;
