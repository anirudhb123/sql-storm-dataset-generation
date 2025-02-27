WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS depth,
        t.imdb_index,
        STRING_AGG(c.person_id::text, ',') AS cast_members
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.imdb_index

    UNION ALL

    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        mh.depth + 1 AS depth,
        t.imdb_index,
        STRING_AGG(c.person_id::text, ',') AS cast_members
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        m.movie_id, t.title, t.production_year, mh.depth, t.imdb_index
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.depth,
    case when mh.cast_members IS NOT NULL then 'Yes' else 'No' end AS has_cast,
    COUNT(DISTINCT c.person_id) AS total_cast_members,
    STRING_AGG(DISTINCT COALESCE(a.name, 'Unknown'), ', ') AS actor_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    (mh.production_year IS NOT NULL AND mh.production_year >= 2000)
    OR (mh.imdb_index LIKE 'A%' AND mh.depth < 3)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.depth
HAVING 
    COUNT(DISTINCT c.person_id) > 0
ORDER BY 
    mh.production_year DESC, mh.depth, mh.title;

