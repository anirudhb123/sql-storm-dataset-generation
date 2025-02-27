WITH movie_ratings AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        COALESCE(moi.info, 'No Rating') AS rating,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY moi.info_type_id) AS rn
    FROM title t
    LEFT JOIN movie_info moi ON t.id = moi.movie_id
    WHERE moi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
),
cast_details AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name, 
        c.type AS role_type,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_order
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN comp_cast_type c ON ci.person_role_id = c.id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_total
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
movies_with_details AS (
    SELECT 
        m.title_id,
        m.title,
        COALESCE(cd.actor_name, 'Unknown Actor') AS actor_name,
        m.rating,
        COALESCE(kc.keyword_total, 0) AS keyword_count
    FROM movie_ratings m
    LEFT JOIN cast_details cd ON m.title_id = cd.movie_id
    LEFT JOIN keyword_count kc ON m.title_id = kc.movie_id
)
SELECT 
    mw.title,
    mw.actor_name,
    mw.rating,
    mw.keyword_count,
    CASE 
        WHEN mw.keyword_count > 5 THEN 'Popular'
        WHEN mw.keyword_count BETWEEN 1 AND 5 THEN 'Moderate'
        ELSE 'Unpopular' 
    END AS popularity_category
FROM movies_with_details mw
WHERE mw.actor_order = 1 
ORDER BY mw.rating DESC NULLS LAST, mw.title;
