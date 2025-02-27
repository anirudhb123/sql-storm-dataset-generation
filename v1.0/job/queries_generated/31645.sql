WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m 
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1 AS depth
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
), 
cast_details AS (
    SELECT 
        ci.movie_id,
        string_agg(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT ci.person_id) AS total_casts,
        MAX(CASE WHEN ci.nr_order = 1 THEN ak.name END) AS lead_actor
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
movie_info_summary AS (
    SELECT 
        m.movie_id,
        COALESCE(mi.info, 'No Info Available') AS movie_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id, mi.info
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    cd.actor_names,
    cd.total_casts,
    cd.lead_actor,
    mis.movie_info,
    mis.keyword_count,
    CASE 
        WHEN mis.keyword_count > 3 THEN 'Highly Tagged'
        WHEN mis.keyword_count BETWEEN 1 AND 3 THEN 'Moderately Tagged'
        ELSE 'Not Tagged'
    END AS tagging_status,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY cd.total_casts DESC) AS actor_ranking
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_details cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    movie_info_summary mis ON mh.movie_id = mis.movie_id
ORDER BY 
    mh.production_year, actor_ranking;
This SQL query performs a comprehensive performance benchmarking against the provided schema, employing various advanced SQL features. It utilizes recursive CTEs to build a movie hierarchy, aggregates casting details, summarizes movie information, and applies window functions for ranking. The final selection crafts a detailed report on movies, including actor information and tagging status, ordered by production year and actor ranks.
