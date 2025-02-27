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
        level + 1
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
        STRING_AGG(DISTINCT t.title, ', ') AS titles,
        AVG(COALESCE(mi.info::int, 0)) AS average_info_score
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
    AS A.name,
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
    total_movies DESC, 
    average_info_score DESC
LIMIT 10;

This query performs the following actions:

1. It uses a recursive Common Table Expression (CTE) to generate a list of actors and the movies they have been involved in, filtering specifically for lead actors.
2. The second CTE aggregates data on these actors, calculating the total number of movies, a comma-separated list of titles, and an average info score.
3. In the final SELECT statement, the results are enriched with a classification (Star, Supporting, Background) based on the average info score.
4. The output is ordered by the total number of movies and the average score, limiting the result to the top 10 performers.
