
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        1 AS hierarchy_level, 
        COALESCE(episode_of_id, 0) AS parent_id 
    FROM 
        aka_title m 
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id, 
        m.title, 
        m.production_year, 
        mh.hierarchy_level + 1 AS hierarchy_level, 
        m.episode_of_id AS parent_id 
    FROM 
        aka_title m 
    INNER JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
),
cast_agg AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
keyword_agg AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ca.cast_names,
        ka.keywords,
        mh.hierarchy_level,
        ROW_NUMBER() OVER (PARTITION BY mh.hierarchy_level ORDER BY mh.production_year DESC) AS rn,
        RANK() OVER (PARTITION BY mh.hierarchy_level ORDER BY mh.production_year DESC) AS movie_rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        cast_agg ca ON mh.movie_id = ca.movie_id
    LEFT JOIN 
        keyword_agg ka ON mh.movie_id = ka.movie_id
),
final_movies AS (
    SELECT 
        *,
        CASE 
            WHEN movie_rank = 1 THEN 'Top Movie'
            WHEN movie_rank <= 5 THEN 'Popular Movie'
            ELSE 'Classic Movie'
        END AS movie_category
    FROM 
        movie_details
    WHERE 
        production_year IS NOT NULL
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_names,
    fm.keywords,
    fm.hierarchy_level,
    fm.movie_category,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = fm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Awards%')) AS award_count
FROM 
    final_movies fm
WHERE 
    fm.hierarchy_level = 2
    AND (fm.keywords IS NULL OR fm.keywords LIKE '%Action%')
ORDER BY 
    fm.production_year DESC, 
    fm.movie_category DESC
LIMIT 100;
