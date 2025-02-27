WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 1990 AND 2020 -- Filter by production year

    UNION ALL

    SELECT 
        lm.Linked_Movie AS movie_id,
        lt.title,
        lt.production_year,
        mh.depth + 1
    FROM 
        movie_link lm
    JOIN 
        aka_title lt ON lm.linked_movie_id = lt.id
    JOIN 
        MovieHierarchy mh ON lm.movie_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cast_info.person_id, 0) AS main_actor_id,
    COALESCE(aka_name.name, 'Unknown') AS main_actor_name,
    COUNT(DISTINCT cm.company_id) AS company_count,
    AVG(mov_info.info_length) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank,
    CASE 
        WHEN mh.depth > 1 THEN 'Sequel/Prequel'
        ELSE 'Standalone'
    END AS movie_type,
    SUM(CASE 
            WHEN mv.keyword IS NOT NULL THEN 1 
            ELSE 0 
        END) AS keyword_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ON mh.movie_id = cast_info.movie_id
LEFT JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mov_info ON mh.movie_id = mov_info.movie_id
LEFT JOIN 
    movie_keyword mv ON mh.movie_id = mv.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, cast_info.person_id, aka_name.name, mh.depth
HAVING 
    COUNT(DISTINCT mc.company_id) > 2
ORDER BY 
    mh.production_year DESC, COUNT(DISTINCT mc.company_id) DESC;
