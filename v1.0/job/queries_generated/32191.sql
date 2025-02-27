WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level,
        t.episode_of_id
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1,
        t.episode_of_id
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
AggregatedRoles AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles_summary,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ar.roles_summary, 'No Roles') AS roles_summary,
        COALESCE(ar.actor_count, 0) AS actor_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        AggregatedRoles ar ON mh.movie_id = ar.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, ar.roles_summary, ar.actor_count
),
TitleStatistics AS (
    SELECT 
        production_year,
        AVG(actor_count) AS avg_actor_count,
        MAX(actor_count) AS max_actor_count,
        MIN(actor_count) AS min_actor_count
    FROM 
        MovieDetails
    GROUP BY 
        production_year
)
SELECT 
    m.title,
    m.production_year,
    m.roles_summary,
    ts.avg_actor_count,
    ts.max_actor_count,
    ts.min_actor_count,
    CASE 
        WHEN m.actor_count > ts.avg_actor_count THEN 'Above Average'
        WHEN m.actor_count < ts.avg_actor_count THEN 'Below Average'
        ELSE 'Average'
    END AS performance_rating
FROM 
    MovieDetails m
JOIN 
    TitleStatistics ts ON m.production_year = ts.production_year
ORDER BY 
    m.production_year DESC, 
    m.actor_count DESC;
