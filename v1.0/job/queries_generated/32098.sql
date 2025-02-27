WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS level
    FROM title m
    WHERE m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

ActorRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS actor_role,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id, r.role
),

ActorsDetails AS (
    SELECT 
        ak.name AS actor_name, 
        mk.movie_id,
        COALESCE(a.role_count, 0) AS role_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN ActorRoles a ON ci.movie_id = a.movie_id AND ak.person_id = ci.person_id
    WHERE ak.name IS NOT NULL
)

SELECT 
    mh.movie_id, 
    mh.title,
    mh.production_year,
    ad.actor_name,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY ad.role_count DESC) AS actor_rank,
    COUNT(DISTINCT ad.actor_name) OVER (PARTITION BY mh.movie_id) AS distinct_actors,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS keyword_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM MovieHierarchy mh
JOIN ActorsDetails ad ON mh.movie_id = ad.movie_id
LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN keyword kw ON mk.keyword_id = kw.id
WHERE mh.level > 1 
GROUP BY mh.movie_id, mh.title, mh.production_year, ad.actor_name
ORDER BY mh.production_year DESC, actor_rank, mh.title;
