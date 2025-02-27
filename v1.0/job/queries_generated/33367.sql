WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(NULLIF(mt.production_year, 0), 'Unknown') AS production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        COALESCE(NULLIF(at.production_year, 0), 'Unknown') AS production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    FIRST_VALUE(mh.title) OVER (PARTITION BY mh.kind_id ORDER BY mh.production_year DESC) AS latest_title_in_kind,
    SUM(mf.info_type_id) FILTER (WHERE mf.info_type_id IS NOT NULL) AS total_info_types
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mf ON mh.movie_id = mf.movie_id
GROUP BY 
    mh.id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, actor_count DESC;
