
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0) AS season_nr,
        COALESCE(mt.episode_nr, 0) AS episode_nr,
        mt.episode_of_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.season_nr IS NOT NULL

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        COALESCE(mt.season_nr, 0),
        COALESCE(mt.episode_nr, 0),
        mt.episode_of_id,
        mh.level + 1
    FROM 
        aka_title mt
        INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
)

SELECT 
    mh.title AS episode_title,
    mh.production_year,
    mh.season_nr,
    mh.episode_nr,
    COALESCE(c.role_id, 0) AS role_count,
    COUNT(DISTINCT m_know.keyword) AS keyword_count,
    STRING_AGG(DISTINCT cc.kind, ', ') AS company_types,
    MAX(pi.info) AS director_info
FROM 
    MovieHierarchy mh
    LEFT JOIN cast_info c ON mh.movie_id = c.movie_id AND c.note IS NULL
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN keyword m_know ON mk.keyword_id = m_know.id
    LEFT JOIN movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN company_type cc ON mc.company_type_id = cc.id
    LEFT JOIN movie_info pi ON mh.movie_id = pi.movie_id AND pi.info_type_id = 1
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.season_nr, mh.episode_nr, c.role_id
HAVING 
    COUNT(DISTINCT m_know.keyword) > 2 AND COALESCE(c.role_id, 0) > 0
ORDER BY 
    mh.production_year DESC, mh.season_nr ASC, mh.episode_nr ASC;
