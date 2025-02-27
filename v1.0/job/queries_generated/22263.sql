WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(c.title, 'Standalone') AS related_title,
        COALESCE(c.linked_movie_id, -1) AS linked_movie_id
    FROM 
        title t
    LEFT JOIN 
        movie_link ml ON t.id = ml.movie_id
    LEFT JOIN 
        title c ON c.id = ml.linked_movie_id
),
actor_movie_info AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        CASE 
            WHEN c.role_id IS NOT NULL THEN 'Featured' 
            ELSE 'Cameo' 
        END AS role_type,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year) AS movie_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS unique_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_summary AS (
    SELECT
        t.title AS movie_title,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        COALESCE(kc.unique_keywords, 0) AS keyword_count,
        MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS summary_info,
        MAX(CASE WHEN mi.info_type_id = 2 THEN mi.info END) AS genre_info
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        keyword_count kc ON t.id = kc.movie_id
    GROUP BY 
        t.id
)
SELECT 
    mh.title AS movie_title,
    mh.production_year,
    mh.related_title,
    COALESCE(mis.total_actors, 0) AS total_actors,
    mis.keyword_count AS unique_keyword_count,
    mis.summary_info,
    mis.genre_info,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mis.total_actors DESC) AS ranking,
    CASE 
        WHEN mh.linked_movie_id IS NOT NULL THEN 'Related Movie Exists'
        ELSE 'No Related Movie'
    END AS relation_status
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_info_summary mis ON mh.title_id = mis.movie_title
ORDER BY 
    mh.production_year DESC, 
    unique_keyword_count DESC NULLS LAST;
