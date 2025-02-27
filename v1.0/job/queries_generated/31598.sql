WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
  
    UNION ALL
  
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link m
    JOIN 
        aka_title t ON m.linked_movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.movie_id = mh.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT CONCAT(aka.name, ' (', rt.role, ')'), ', ') AS cast_list
    FROM 
        cast_info ci
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieAttributes AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        MAX(t.production_year) AS production_year,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COALESCE(MAX(mo.info), 'No additional info') AS additional_info
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_info mo ON t.id = mo.movie_id AND mo.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
    GROUP BY 
        t.id, t.title
)
SELECT 
    mh.title,
    mh.production_year,
    c.actor_count,
    c.cast_list,
    ma.keywords,
    ma.additional_info
FROM 
    MovieHierarchy mh
JOIN 
    CastWithRoles c ON mh.movie_id = c.movie_id
JOIN 
    MovieAttributes ma ON mh.movie_id = ma.movie_id
WHERE 
    c.actor_count > 5
ORDER BY 
    mh.production_year DESC, c.actor_count DESC
LIMIT 10;
