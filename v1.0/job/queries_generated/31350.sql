WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::text AS episode_title,
        mt.season_nr,
        mt.episode_nr,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        et1.title AS episode_title,
        et.season_nr,
        et.episode_nr,
        mh.hierarchy_level + 1
    FROM 
        aka_title et
    JOIN 
        aka_title et1 ON et1.episode_of_id = et.id 
    JOIN 
        MovieHierarchy mh ON et1.season_nr = mh.season_nr AND et1.episode_nr = mh.episode_nr
)

SELECT 
    mh.title AS movie_title,
    mh.production_year AS release_year,
    mh.episode_title,
    COUNT(DISTINCT c.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
    CASE 
        WHEN mh.season_nr IS NOT NULL AND mh.episode_nr IS NOT NULL THEN 'TV Series'
        ELSE 'Movie'
    END AS type 
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.episode_title, mh.season_nr, mh.episode_nr
ORDER BY 
    mh.production_year DESC, mh.hierarchy_level, movie_title;
