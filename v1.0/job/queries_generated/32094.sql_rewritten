WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.season_nr,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.season_nr IS NOT NULL

    UNION ALL

    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.season_nr,
        mh.level + 1
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
)


SELECT 
    ak.name AS actor_name,
    mh.title AS movie_title,
    mh.season_nr,
    COUNT(DISTINCT cc.person_id) AS total_cast,
    STRING_AGG(DISTINCT co.name, ', ') AS company_names,
    SUM(CASE WHEN mw.production_year IS NOT NULL THEN 1 ELSE 0 END) AS produced_movies,
    MAX(COALESCE(pi.info, 'No Info')) AS additional_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_info pi ON mh.movie_id = pi.movie_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Release Date')
LEFT JOIN 
    aka_title mw ON mh.movie_id = mw.id
GROUP BY 
    ak.name, mh.title, mh.season_nr
ORDER BY 
    total_cast DESC, produced_movies DESC, mh.title ASC;