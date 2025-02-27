WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        COALESCE(NULLIF(aka.title, ''), title.title) AS movie_title,
        title.production_year,
        1 AS depth
    FROM 
        aka_title aka 
    JOIN 
        title ON aka.movie_id = title.id
    LEFT JOIN 
        aka_title mt ON mt.episode_of_id = aka.movie_id
    WHERE 
        aka.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        COALESCE(NULLIF(aka.title, ''), title.title) AS movie_title,
        title.production_year,
        depth + 1
    FROM 
        aka_title aka 
    JOIN 
        title ON aka.movie_id = title.id
    JOIN 
        MovieHierarchy mt ON mt.movie_id = aka.episode_of_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COUNT(CASE WHEN c.note IS NOT NULL THEN 1 END) AS cast_count,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mh.production_year) AS total_cast_by_year,
    STRING_AGG(DISTINCT cn.name, ', ') AS character_names,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(c.id) DESC) AS yearly_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    char_name cn ON c.person_role_id = cn.id
WHERE 
    mh.depth < 3
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year
ORDER BY 
    mh.production_year DESC, cast_count DESC
LIMIT 50;
