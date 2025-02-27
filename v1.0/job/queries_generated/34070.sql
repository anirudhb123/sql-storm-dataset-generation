WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level,
        CAST(t.title AS VARCHAR(255)) AS path,
        t.imdb_index
    FROM 
        aka_title t
    JOIN 
        title m ON t.movie_id = m.id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        linked.linked_movie_id,
        l.title,
        l.production_year,
        l.kind_id,
        mh.level + 1,
        CONCAT(mh.path, ' -> ', l.title),
        l.imdb_index
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link linked ON mh.movie_id = linked.movie_id
    JOIN 
        title l ON linked.linked_movie_id = l.id
    WHERE 
        l.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(c.person_id) AS num_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    AVG(mr.info) AS avg_rating
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id AND c.nr_order IS NOT NULL
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    (SELECT movie_id, AVG(CAST(info AS FLOAT)) AS info FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating') GROUP BY movie_id) mr ON mh.movie_id = mr.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
HAVING 
    COUNT(c.person_id) > 5
ORDER BY 
    mh.production_year DESC, num_actors DESC;
