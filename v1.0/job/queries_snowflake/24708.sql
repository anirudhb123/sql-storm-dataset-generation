
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(SUBSTR(mt.title, 1, 5), 'Unknown') AS short_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL 

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(SUBSTR(mt.title, 1, 5), 'Unknown') AS short_title,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mt.id = mh.movie_id
    WHERE 
        mh.level < 3
),

cast_details AS (
    SELECT 
        ci.movie_id,
        LISTAGG(aka.name, ', ') AS cast_names,
        COUNT(DISTINCT ci.person_id) AS num_cast_members,
        COUNT(DISTINCT ci.role_id) AS unique_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    GROUP BY 
        ci.movie_id
),

movie_info_agg AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT it.info, '; ') AS movie_info,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
),

final_result AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        cd.cast_names,
        cd.num_cast_members,
        mi.movie_info,
        mi.info_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cd.num_cast_members DESC) AS rn
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_details cd ON mh.movie_id = cd.movie_id
    LEFT JOIN 
        movie_info_agg mi ON mh.movie_id = mi.movie_id
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_names,
    fr.num_cast_members,
    fr.movie_info,
    fr.info_count
FROM 
    final_result fr
WHERE 
    (fr.production_year >= 2000 AND fr.num_cast_members IS NOT NULL)
    OR (fr.production_year < 2000 AND fr.cast_names IS NULL)
ORDER BY 
    fr.production_year DESC, fr.rn
LIMIT 10;
