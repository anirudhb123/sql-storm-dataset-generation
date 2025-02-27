WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 5
),
ActorDistribution AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        MovieHierarchy mh ON c.movie_id = mh.movie_id
    GROUP BY 
        c.person_id
),
MostProductiveActors AS (
    SELECT 
        a.person_id,
        a.movie_count,
        ROW_NUMBER() OVER (ORDER BY a.movie_count DESC) AS rank
    FROM 
        ActorDistribution a
    WHERE 
        a.movie_count > 1
),
ActorNames AS (
    SELECT 
        ak.person_id,
        STRING_AGG(ak.name, ', ') AS names
    FROM 
        aka_name ak
    JOIN 
        MostProductiveActors ma ON ak.person_id = ma.person_id
    GROUP BY 
        ak.person_id
),
ActorRoles AS (
    SELECT
        c.person_id,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order < 5
    GROUP BY 
        c.person_id
)

SELECT 
    ans.names,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    ans.roles,
    MIN(CASE WHEN mh.production_year IS NULL THEN 'N/A' ELSE mh.production_year END) AS first_movie_year,
    MAX(mh.production_year) AS last_movie_year,
    (SELECT COUNT(*) FROM role_type) AS total_roles
FROM 
    ActorNames ans
JOIN 
    MovieHierarchy mh ON ans.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = mh.movie_id)
LEFT JOIN 
    ActorRoles ar ON ans.person_id = ar.person_id
WHERE 
    (mh.production_year IS NOT NULL AND mh.production_year BETWEEN 2000 AND 2023)
    OR ans.roles IS NOT NULL
GROUP BY 
    ans.person_id, ans.names
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    movie_count DESC
FETCH FIRST 10 ROWS ONLY;
