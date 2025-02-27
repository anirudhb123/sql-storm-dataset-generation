WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS keyword_rank,
        COALESCE(t.season_nr, 0) + COALESCE(t.episode_nr, 0) AS episode_metric
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.season_nr, t.episode_nr
),
filtered_titles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.keyword_rank,
        rt.episode_metric,
        ROW_NUMBER() OVER (ORDER BY rt.episode_metric DESC) AS episode_rank
    FROM 
        ranked_titles rt
    WHERE 
        rt.keyword_rank = 1
),

movie_cast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        MAX(c.nr_order) AS max_order
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
)

SELECT 
    ft.title,
    ft.production_year,
    COALESCE(mc.cast_count, 0) AS total_cast,
    ft.episode_metric,
    CASE 
        WHEN mc.max_order IS NULL THEN 'No cast data available'
        ELSE CAST(mc.max_order AS text)
    END AS max_cast_order
FROM 
    filtered_titles ft
LEFT JOIN 
    movie_cast mc ON ft.title_id = mc.movie_id
WHERE 
    (ft.episode_metric IS NULL OR ft.episode_metric > 5)
    AND (ft.production_year IS NOT NULL OR ft.title IS NOT NULL)
ORDER BY 
    ft.production_year DESC,
    ft.episode_metric ASC
FETCH FIRST 100 ROWS ONLY;

WITH RECURSIVE movie_links AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS link_level
    FROM 
        movie_link ml
    WHERE 
        ml.link_type_id IS NOT NULL
    UNION ALL
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        link_level + 1
    FROM 
        movie_links ml
    JOIN 
        movie_link next ON ml.linked_movie_id = next.movie_id
    WHERE 
        next.link_type_id IS NOT NULL AND link_level < 5
)

SELECT 
    c.name,
    COUNT(DISTINCT ml.linked_movie_id) AS depth_movie_count
FROM 
    company_name c
LEFT JOIN 
    movie_companies mc ON c.id = mc.company_id
LEFT JOIN 
    movie_links ml ON mc.movie_id = ml.movie_id
GROUP BY 
    c.name
HAVING 
    COUNT(DISTINCT ml.linked_movie_id) >= 1
ORDER BY 
    depth_movie_count DESC;
