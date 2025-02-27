WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CastStats AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles
    FROM
        cast_info ci
    GROUP BY
        ci.movie_id
),
TitleSummary AS (
    SELECT
        a.id AS movie_id,
        a.title,
        a.production_year,
        COALESCE(cs.actor_count, 0) AS total_actors,
        COALESCE(cs.avg_roles, 0) AS average_roles,
        mh.depth
    FROM
        aka_title a
    LEFT JOIN
        CastStats cs ON a.id = cs.movie_id
    JOIN
        MovieHierarchy mh ON a.id = mh.movie_id
)
SELECT 
    ts.title,
    ts.production_year,
    ts.total_actors,
    ts.average_roles,
    mh.depth,
    CASE
        WHEN ts.total_actors > 10 THEN 'Blockbuster'
        WHEN ts.total_actors BETWEEN 5 AND 10 THEN 'Average'
        ELSE 'Low Budget'
    END AS budget_category,
    STRING_AGG(DISTINCT cn.name, ', ') AS character_names
FROM 
    TitleSummary ts
LEFT JOIN 
    complete_cast cc ON ts.movie_id = cc.movie_id
LEFT JOIN 
    char_name cn ON cc.subject_id = cn.id
GROUP BY 
    ts.title, ts.production_year, ts.total_actors, ts.average_roles, mh.depth
ORDER BY 
    ts.production_year DESC, ts.total_actors DESC;
This query performs an elaborate benchmark of movie titles along with their associated cast count and other derived metrics, utilizing recursive CTEs for movie hierarchies, subqueries for statistics, and various joins to aggregate character names. It categorizes movies based on actor count and provides a detailed overview for performance analysis.
