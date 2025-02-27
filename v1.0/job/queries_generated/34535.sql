WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        1 AS level 
    FROM 
        aka_title t 
    WHERE 
        t.season_nr IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year, 
        mh.level + 1 AS level 
    FROM 
        aka_title t 
    JOIN 
        movie_link ml ON ml.linked_movie_id = t.id 
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
CastWithRoles AS (
    SELECT 
        ci.movie_id, 
        a.name AS actor_name, 
        r.role, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords 
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(cwr.actor_name, 'No Cast') AS actor_name,
    COALESCE(cwr.role, 'No Role') AS role,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    mh.level,
    CASE 
        WHEN mh.production_year < 2000 THEN '20th Century'
        WHEN mh.production_year BETWEEN 2000 AND 2023 THEN '21st Century'
        ELSE 'Future Release'
    END AS release_century
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastWithRoles cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.production_year DESC, 
    mh.movie_title ASC, 
    cwr.role_order ASC;
