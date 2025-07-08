
WITH RECURSIVE actor_hierarchy AS (
    SELECT c.movie_id, a.person_id, a.name, 1 AS depth
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE c.nr_order = 1  
    
    UNION ALL
    
    SELECT c.movie_id, a.person_id, a.name, ah.depth + 1
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN actor_hierarchy ah ON c.movie_id = ah.movie_id
    WHERE c.nr_order > 1  
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT a.name) AS cast_names
    FROM aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    GROUP BY m.id, m.title, m.production_year
),
keyword_stats AS (
    SELECT
        mk.movie_id,
        COUNT(k.id) AS total_keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_summary AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.cast_names,
        COALESCE(ks.total_keywords, 0) AS total_keywords
    FROM movie_details md
    LEFT JOIN keyword_stats ks ON md.movie_id = ks.movie_id
),
final_ranking AS (
    SELECT 
        ms.*,
        RANK() OVER (ORDER BY ms.production_year DESC, ms.total_cast DESC) AS rank
    FROM movie_summary ms
)
SELECT 
    fr.rank,
    fr.title,
    fr.production_year,
    fr.total_cast,
    fr.cast_names,
    fr.total_keywords,
    CASE 
        WHEN fr.total_cast > 10 THEN 'Ensemble Cast'
        ELSE 'Limited Cast' 
    END AS cast_description
FROM final_ranking fr
WHERE fr.total_keywords > 0
ORDER BY fr.rank;
