WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.production_year >= 2000
    UNION ALL
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy AS mh
    JOIN movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN aka_title AS at ON ml.linked_movie_id = at.id
),
ActorStats AS (
    SELECT
        ak.person_id,
        ak.name,
        COUNT(ci.movie_id) AS movie_count,
        AVG(CASE WHEN c.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_lead_role
    FROM
        aka_name AS ak
    JOIN cast_info AS ci ON ak.person_id = ci.person_id
    LEFT JOIN role_type AS c ON ci.role_id = c.id
    GROUP BY
        ak.person_id,
        ak.name
),
RecentMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ak.person_id) AS actor_count
    FROM
        MovieHierarchy AS mh
    JOIN cast_info AS ci ON mh.movie_id = ci.movie_id
    JOIN aka_name AS ak ON ci.person_id = ak.person_id
    WHERE
        mh.production_year > YEAR(CURRENT_DATE) - 5
    GROUP BY
        mh.movie_id,
        mh.title,
        mh.production_year
),
CombinedStats AS (
    SELECT
        rm.title,
        rm.production_year,
        rm.actor_count,
        COALESCE(as.movie_count, 0) AS total_actors,
        COALESCE(as.avg_lead_role, 0) AS avg_lead_score
    FROM
        RecentMovies AS rm
    LEFT JOIN ActorStats AS as ON rm.actor_count = as.movie_count
)
SELECT
    cs.title,
    cs.production_year,
    cs.actor_count,
    cs.total_actors,
    cs.avg_lead_score,
    CASE 
        WHEN cs.avg_lead_score > 0.5 THEN 'High'
        WHEN cs.avg_lead_score = 0 THEN 'None'
        ELSE 'Low'
    END AS lead_role_quality
FROM
    CombinedStats AS cs
WHERE
    cs.actor_count > 5
ORDER BY
    cs.production_year DESC, cs.actor_count DESC;

This query performs several interesting operations:
1. It uses a recursive common table expression (CTE) to create a hierarchy of movies linked by references.
2. It calculates statistics about actors, such as the number of movies they have appeared in and the average score for being in a lead role.
3. It extracts recent movies from the constructed hierarchy.
4. It combines the results to provide a comprehensive view, including a calculated field that categorizes the quality of lead roles.
5. Finally, it provides filters to return only movies with more than five actors and orders the results primarily by the production year and actor count.
