WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        cc.linked_movie_id,
        m.title,
        m.production_year,
        ch.level + 1
    FROM 
        movie_link cc
    JOIN 
        aka_title m ON cc.linked_movie_id = m.id
    JOIN 
        movie_hierarchy ch ON cc.movie_id = ch.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
role_summary AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    INNER JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL
    GROUP BY 
        ci.movie_id, rt.role
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
complete_info AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(rs.role, 'Unknown') AS role,
        rs.role_count,
        ks.keywords
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        role_summary rs ON m.movie_id = rs.movie_id
    LEFT JOIN 
        keyword_summary ks ON m.movie_id = ks.movie_id
),
final_results AS (
    SELECT 
        c.*,
        CASE 
            WHEN c.production_year < 2000 THEN 'Classic'
            WHEN c.production_year BETWEEN 2000 AND 2020 THEN 'Modern'
            WHEN c.production_year > 2020 THEN 'Recent'
            ELSE 'Unknown Era'
        END AS era,
        ROW_NUMBER() OVER (PARTITION BY c.role ORDER BY c.production_year DESC) AS role_rank,
        RANK() OVER (ORDER BY c.production_year DESC) AS movie_rank
    FROM 
        complete_info c
    WHERE 
        c.keywords IS NOT NULL
)
SELECT 
    title,
    production_year,
    role,
    role_count,
    keywords,
    era,
    role_rank,
    movie_rank
FROM 
    final_results
WHERE 
    (era = 'Classic' AND role_count > 4)
    OR (era = 'Modern' AND role_count IS NULL)
ORDER BY 
    movie_rank, era DESC, title;

