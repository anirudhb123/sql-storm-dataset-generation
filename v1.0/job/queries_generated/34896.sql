WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        1 AS level
    FROM cast_info c
    WHERE c.nr_order = 1
    
    UNION ALL

    SELECT 
        c.id,
        c.person_id,
        c.movie_id,
        c.nr_order,
        ah.level + 1
    FROM cast_info c
    JOIN actor_hierarchy ah ON c.movie_id = ah.movie_id AND c.nr_order = ah.nr_order + 1
),
movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        COALESCE(mo.info, 'No info') AS movie_info,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(CASE WHEN mc.note IS NOT NULL THEN mc.note ELSE 'No Note' END) AS company_note
    FROM aka_title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_info mo ON t.id = mo.movie_id AND mo.info_type_id = 1
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    GROUP BY t.id, t.title, t.production_year, a.name, mo.info
),
ranked_movies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.company_count DESC) AS rank
    FROM movie_details md
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    rm.movie_info,
    rm.company_count,
    rm.company_note,
    CASE 
        WHEN rm.rank <= 3 THEN 'Top 3 Movies'
        ELSE 'Other Movies'
    END AS movie_category
FROM ranked_movies rm
WHERE rm.company_count IS NOT NULL 
AND EXISTS (
    SELECT 1 
    FROM actor_hierarchy ah 
    WHERE ah.movie_id = rm.title_id
)
ORDER BY rm.production_year DESC, rm.company_count DESC;
