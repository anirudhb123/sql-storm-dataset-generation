WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.id AS movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        mh.level + 1
    FROM 
        aka_title mh
    INNER JOIN movie_link ml ON mh.id = ml.linked_movie_id
    WHERE 
        ml.movie_id IN (SELECT movie_id FROM MovieHierarchy)
),

ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),

MovieStats AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT mkw.keyword_id) AS keyword_count,
        MAX(mk.info) AS longest_rating,
        COALESCE(MAX(ci.nr_order), 0) AS max_role_order
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoles ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mkw ON mh.movie_id = mkw.movie_id
    LEFT JOIN 
        movie_info mk ON mh.movie_id = mk.movie_id AND mk.info_type_id = (SELECT id FROM info_type WHERE info = 'rating' LIMIT 1)
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)

SELECT 
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.keyword_count,
    CASE 
        WHEN ms.max_role_order > 5 THEN 'A-List'
        WHEN ms.max_role_order > 0 THEN 'Supporting'
        ELSE 'Unknown'
    END AS role_level,
    COALESCE(ROUND(AVG(LENGTH(mk.info::text) - LENGTH(REPLACE(mk.info::text, ' ', '')) + 1), 2), 0) AS avg_word_count
FROM 
    MovieStats ms
LEFT JOIN 
    movie_info mk ON ms.movie_id = mk.movie_id
GROUP BY 
    ms.movie_id, ms.title, ms.production_year, ms.actor_count, ms.keyword_count, ms.max_role_order
ORDER BY 
    ms.production_year DESC, role_level DESC, actor_count DESC
OFFSET 5 LIMIT 10;
