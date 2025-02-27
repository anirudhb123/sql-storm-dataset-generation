WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.id AS title_id
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mn.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.id AS title_id
    FROM 
        movie_link mn
    JOIN 
        MovieHierarchy mh ON mn.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON mn.linked_movie_id = mt.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    CASE 
        WHEN mh.level > 1 THEN 'Sequel or Franchise'
        ELSE 'Original Movie'
    END AS movie_type,
    COALESCE(CAST(SUM(mo.info IS NOT NULL) AS INTEGER), 0) AS num_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.id
LEFT JOIN 
    aka_name ak ON ca.person_id = ak.person_id
LEFT JOIN 
    movie_info mo ON mh.movie_id = mo.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
ORDER BY 
    mh.production_year DESC, num_cast_members DESC;

This query builds a recursive Common Table Expression (CTE) to create a hierarchy of movies and their sequels or franchises from the `aka_title` table. It then performs several outer joins to gather information about the complete cast, the names of the cast members, and additional movie info, aggregating and consolifying the information into a readable output. Each movie's type is categorized based on its hierarchy level, and the final result is ordered by production year and the number of cast members.
