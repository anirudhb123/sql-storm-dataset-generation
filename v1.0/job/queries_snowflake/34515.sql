
WITH RECURSIVE actor_movie_recursion AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ca.nr_order,
        1 AS level
    FROM 
        cast_info ca
    WHERE 
        ca.person_role_id = (SELECT id FROM role_type WHERE role = 'lead actor')
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        ca.movie_id,
        ca.nr_order,
        amr.level + 1
    FROM 
        cast_info ca
    JOIN actor_movie_recursion amr ON ca.movie_id = amr.movie_id
    WHERE 
        ca.nr_order > amr.nr_order
),
actor_summary AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT amr.movie_id) AS total_movies,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS titles,
        AVG(COALESCE(CAST(mi.info AS INTEGER), 0)) AS average_info_score
    FROM 
        actor_movie_recursion amr
    JOIN 
        aka_name ak ON ak.person_id = amr.person_id
    JOIN 
        title t ON t.id = amr.movie_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = amr.movie_id
    GROUP BY 
        ak.name
)
SELECT 
    A.name,
    A.total_movies,
    A.titles,
    A.average_info_score,
    CASE 
        WHEN A.average_info_score > 90 THEN 'Star'
        WHEN A.average_info_score BETWEEN 70 AND 90 THEN 'Supporting'
        ELSE 'Background'
    END AS role_classification
FROM 
    actor_summary A
ORDER BY 
    A.total_movies DESC, 
    A.average_info_score DESC
LIMIT 10;
