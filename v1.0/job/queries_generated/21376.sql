WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(episode_of.title, 'N/A') AS episode_of_title,
        mt.season_nr,
        mt.episode_nr,
        1 AS depth
    FROM aka_title mt
    LEFT JOIN aka_title episode_of ON mt.episode_of_id = episode_of.id
    WHERE mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        COALESCE(e.title, 'N/A') AS episode_of_title,
        m.season_nr,
        m.episode_nr,
        mh.depth + 1
    FROM movie_link ml
    JOIN aka_title m ON ml.linked_movie_id = m.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.episode_of_title,
    mh.season_nr,
    mh.episode_nr,
    mh.depth,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN ci.nr_order ELSE NULL END) AS avg_order,
    STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.name IS NOT NULL) AS cast_names,
    SUM(CASE 
        WHEN mt.info_type_id IS NULL THEN 1 
        ELSE 0 
    END) AS info_type_null_count
FROM movie_hierarchy mh
LEFT JOIN cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN name cn ON ci.person_id = cn.imdb_id
LEFT JOIN movie_info mt ON mh.movie_id = mt.movie_id
GROUP BY 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.episode_of_title,
    mh.season_nr,
    mh.episode_nr,
    mh.depth
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 AND 
    AVG(ci.nr_order) IS NOT NULL
ORDER BY 
    mh.production_year DESC,
    mh.depth ASC,
    total_cast DESC
LIMIT 50;
