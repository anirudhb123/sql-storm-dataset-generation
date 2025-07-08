
WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR) AS full_title
    FROM aka_title mt
    WHERE mt.production_year BETWEEN 2000 AND 2020
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mk.title,
        mk.production_year,
        mh.level + 1,
        CONCAT(mh.full_title, ' -> ', mk.title) AS full_title
    FROM movie_link ml
    JOIN aka_title mk ON ml.linked_movie_id = mk.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE mh.level < 5
),

cast_stats AS (
    SELECT
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        SUM(CASE 
            WHEN r.role LIKE 'Actor%' THEN 1 
            ELSE 0 
        END) AS actor_count,
        SUM(CASE 
            WHEN r.role LIKE 'Director%' THEN 1 
            ELSE 0 
        END) AS director_count
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id
),

keyword_analysis AS (
    SELECT
        mk.movie_id,
        LISTAGG(kw.keyword, ', ') AS keywords,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY mk.movie_id
),

movie_info_summary AS (
    SELECT
        m.id AS movie_id,
        COALESCE(ki.keywords, 'No keywords') AS keywords,
        cs.total_cast,
        cs.actor_count,
        cs.director_count
    FROM aka_title m
    LEFT JOIN keyword_analysis ki ON m.id = ki.movie_id
    LEFT JOIN cast_stats cs ON m.id = cs.movie_id
)

SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.full_title,
    mis.keywords,
    mis.total_cast,
    mis.actor_count,
    mis.director_count
FROM movie_hierarchy mh
LEFT JOIN movie_info_summary mis ON mh.movie_id = mis.movie_id
WHERE mh.level <= 3
ORDER BY mh.production_year DESC, mh.level, mis.actor_count DESC
