WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        title mt ON mk.keyword_id = mt.id
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mc.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link mc
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
    JOIN 
        title mt ON mc.linked_movie_id = mt.id
    WHERE 
        mk.keyword_id IS NOT NULL
),
ranked_cast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
agg_movie_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(DISTINCT c.actor_name) AS total_actors,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_list
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        ranked_cast c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%description%')
    GROUP BY 
        mh.movie_id, mh.title
),
keywords_with_index AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        MAX(CONCAT(k.keyword, ' (', k.phonetic_code, ')')) AS keyword_info
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    am.movie_id,
    am.title,
    am.total_actors,
    am.actors_list,
    kw.keyword_count,
    kw.keyword_info
FROM 
    agg_movie_info am
LEFT JOIN 
    keywords_with_index kw ON am.movie_id = kw.movie_id
WHERE 
    (am.total_actors IS NULL OR am.total_actors > 0)
    AND (kw.keyword_count IS NOT NULL OR am.title IS NOT NULL)
ORDER BY 
    am.title ASC,
    kw.keyword_count DESC;
