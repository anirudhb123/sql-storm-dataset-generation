WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    INNER JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
, CastWithRoles AS (
    SELECT
        ca.movie_id,
        ca.person_id,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY r.role) AS role_rank
    FROM
        cast_info ca
    INNER JOIN
        role_type r ON ca.role_id = r.id
)
, MovieDetails AS (
    SELECT
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COALESCE(c.role_name, 'Uncredited') AS main_role,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        MovieHierarchy mh
    LEFT JOIN
        CastWithRoles c ON mh.movie_id = c.movie_id
    GROUP BY
        mh.movie_id, mh.movie_title, mh.production_year, c.role_name
)
SELECT
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.main_role,
    md.actor_count,
    CASE 
        WHEN md.actor_count IS NULL THEN 'No actors'
        WHEN md.actor_count < 5 THEN 'Few actors'
        ELSE 'Many actors'
    END AS actor_summary,
    (
        SELECT STRING_AGG(p.name, ', ') 
        FROM aka_name p
        WHERE p.person_id IN (SELECT DISTINCT person_id FROM cast_info ci WHERE ci.movie_id = md.movie_id)
    ) AS actor_names,
    (SELECT COUNT(DISTINCT ci.note) 
     FROM cast_info ci 
     WHERE ci.movie_id = md.movie_id AND ci.note IS NOT NULL) AS unique_notes_count
FROM
    MovieDetails md
ORDER BY
    md.production_year DESC,
    md.actor_count DESC;
