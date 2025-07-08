
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(t.season_nr, 0) AS season_nr,
        COALESCE(t.episode_nr, 0) AS episode_nr,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        aka_title t ON m.id = t.episode_of_id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        t.id,
        t.title,
        COALESCE(t.season_nr, 0),
        COALESCE(t.episode_nr, 0),
        level + 1
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.season_nr,
    mh.episode_nr,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
    AVG(CAST(pi.info AS FLOAT)) AS average_person_info,
    CASE 
        WHEN mh.season_nr > 0 THEN 'Series'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    person_info pi ON ci.person_id = pi.person_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
GROUP BY 
    mh.movie_id, mh.title, mh.season_nr, mh.episode_nr
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    total_cast DESC, mh.title;
