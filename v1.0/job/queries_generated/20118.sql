WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(l.linked_movie_id, -1) AS linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link l ON mt.id = l.movie_id
    WHERE 
        mt.production_year >= 1990
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(l.linked_movie_id, -1),
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title mt ON mh.linked_movie_id = mt.id
    LEFT JOIN 
        movie_link l ON mt.id = l.movie_id
    WHERE 
        mh.level < 3
),
AggregatedInfo AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        STRING_AGG(DISTINCT COALESCE(k.keyword, 'Unknown'), ', ') AS keywords,
        MAX(CASE WHEN mi.info_type_id IS NOT NULL THEN mi.info ELSE 'No Info' END) AS info
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    ai.movie_id,
    ai.title,
    ai.production_year,
    ai.num_actors,
    ai.keywords,
    ai.info,
    nt.name AS role_name,
    COUNT(DISTINCT c.person_role_id) AS total_roles,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present
FROM 
    AggregatedInfo ai
LEFT JOIN 
    cast_info ci ON ai.movie_id = ci.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    name nt ON ci.person_id = nt.imdb_id AND nt.gender = 'M'
WHERE 
    ai.production_year > 2000
GROUP BY 
    ai.movie_id, ai.title, ai.production_year, ai.num_actors, ai.keywords, ai.info, nt.name
HAVING 
    COUNT(DISTINCT ci.person_role_id) > 0
ORDER BY 
    ai.num_actors DESC, ai.production_year DESC, ai.title;
