WITH RECURSIVE ActorHierarchy AS (
    SELECT
        ca.id AS actor_id,
        ka.name AS actor_name,
        1 AS level
    FROM
        cast_info ca
    JOIN
        aka_name ka ON ca.person_id = ka.person_id
    WHERE
        ka.name IS NOT NULL
    
    UNION ALL
    
    SELECT
        ca.id AS actor_id,
        ka.name AS actor_name,
        ah.level + 1
    FROM
        ActorHierarchy ah
    JOIN
        cast_info ca ON ca.movie_id = (SELECT movie_id FROM movie_link ml WHERE ml.linked_movie_id = ah.actor_id LIMIT 1)
    JOIN
        aka_name ka ON ca.person_id = ka.person_id
    WHERE
        ka.name IS NOT NULL AND ah.level < 3
),
MovieDetail AS (
    SELECT
        m.id AS movie_id,
        m.title,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Year'
            ELSE m.production_year::TEXT
        END AS production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COALESCE(
            STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name),
            'No Companies'
        ) AS company_names
    FROM
        aka_title m
    LEFT JOIN
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        m.id
),
ActorMovieStats AS (
    SELECT
        ah.actor_id,
        ah.actor_name,
        COUNT(dm.movie_id) AS movie_count,
        AVG(dm.company_count) AS avg_company_per_movie
    FROM
        ActorHierarchy ah
    JOIN
        MovieDetail dm ON ah.actor_id IN (SELECT person_id FROM cast_info WHERE movie_id = dm.movie_id)
    GROUP BY
        ah.actor_id, ah.actor_name
)
SELECT
    ams.actor_id,
    ams.actor_name,
    ams.movie_count,
    ams.avg_company_per_movie,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ams.actor_id)) AS info_count,
    CASE 
        WHEN ams.avg_company_per_movie > 2 THEN 'High'
        WHEN ams.avg_company_per_movie BETWEEN 1 AND 2 THEN 'Medium'
        ELSE 'Low'
    END AS company_association_level
FROM
    ActorMovieStats ams
ORDER BY
    ams.movie_count DESC, ams.actor_name;

This SQL query utilizes a recursive common table expression (CTE) to build a hierarchy of actors based on their connections through movies. It follows with aggregating movie details to count companies associated with those movies, and further aggregates actor statistics, ultimately producing a comprehensive report that ranks and categorizes actors based on the number of movies they've been in and their average company association, including informative case expressions and correlated subqueries.
