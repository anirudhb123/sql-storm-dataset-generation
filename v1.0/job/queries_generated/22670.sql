WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.production_year, 0) AS production_year,
        COALESCE(mt.kind_id, 999) AS kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mv.linked_movie_id AS movie_id,
        mv.linked_title AS title,
        COALESCE(mv.production_year, 0) AS production_year,
        COALESCE(mv.kind_id, 999) AS kind_id,
        mh.depth + 1
    FROM 
        movie_link mv
    JOIN 
        movie_hierarchy mh ON mv.movie_id = mh.movie_id
    WHERE 
        mv.link_type_id IN (SELECT id FROM link_type WHERE link ILIKE '%continuation%')
),
actor_counts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS unique_actors
    FROM 
        cast_info c
    INNER JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE 
        an.name IS NOT NULL AND an.name <> ''
    GROUP BY 
        c.movie_id
),
high_profile_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ac.unique_actors, 0) AS actor_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        actor_counts ac ON mh.movie_id = ac.movie_id
    WHERE 
        (mh.kind_id = 1 OR mh.kind_id = 2) -- Filter for specific movie types
        AND mh.depth < 3
    ORDER BY 
        actor_count DESC,
        mh.production_year DESC
),
result_set AS (
    SELECT
        hpm.title,
        hpm.production_year,
        hpm.actor_count,
        ROW_NUMBER() OVER (PARTITION BY hpm.production_year ORDER BY hpm.actor_count DESC) AS rank_within_year
    FROM 
        high_profile_movies hpm
)
SELECT 
    rs.title,
    rs.production_year,
    rs.actor_count,
    CASE 
        WHEN rs.rank_within_year <= 5 THEN 'Top 5'
        ELSE 'Below Top 5'
    END AS ranking_category
FROM 
    result_set rs
WHERE 
    rs.actor_count IS NOT NULL
    AND (rs.actor_count > 5 OR rs.production_year > 2000)
ORDER BY 
    rs.production_year DESC, 
    rs.actor_count DESC;
