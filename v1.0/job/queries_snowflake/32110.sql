
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(0 AS INTEGER) AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= (SELECT MIN(production_year) FROM aka_title)

    UNION ALL

    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        mh.level < 3
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS role,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        SUM(CASE WHEN ci.role = 'actor' THEN ci.total_cast ELSE 0 END) AS actor_count,
        SUM(CASE WHEN ci.role = 'director' THEN ci.total_cast ELSE 0 END) AS director_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastInfoWithRoles ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    ORDER BY 
        mh.production_year DESC
    LIMIT 10
)
SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    COALESCE(tm.actor_count, 0) AS actor_count,
    COALESCE(tm.director_count, 0) AS director_count,
    LISTAGG(DISTINCT ca.name, ', ') WITHIN GROUP (ORDER BY ca.name) AS cast_names,
    CASE
        WHEN tm.actor_count > 5 THEN 'Highly Cast'
        ELSE 'Moderate Cast'
    END AS cast_rating
FROM
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ca ON ci.person_id = ca.person_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.actor_count, tm.director_count
HAVING 
    COUNT(DISTINCT ca.name) > 0
ORDER BY 
    tm.production_year DESC, actor_count DESC;
