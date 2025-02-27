WITH RECURSIVE movie_graph AS (
    SELECT 
        mt.movie_id,
        t.title,
        mt.company_id,
        mc.name AS company_name,
        1 AS depth
    FROM 
        movie_companies mt
    JOIN 
        company_name mc ON mt.company_id = mc.id
    JOIN 
        title t ON mt.movie_id = t.id
    WHERE 
        mc.country_code = 'USA'

    UNION ALL

    SELECT 
        mt.movie_id,
        t.title,
        mt.company_id,
        mc.name AS company_name,
        mg.depth + 1
    FROM 
        movie_companies mt
    JOIN 
        company_name mc ON mt.company_id = mc.id
    JOIN 
        title t ON mt.movie_id = t.id
    JOIN 
        movie_graph mg ON mg.company_id = mt.company_id
    WHERE 
        mg.depth < 3
),
aggregated_data AS (
    SELECT 
        mg.movie_id,
        mg.title,
        COUNT(DISTINCT mg.company_id) AS company_count,
        STRING_AGG(DISTINCT mg.company_name, ', ') AS company_names,
        CASE 
            WHEN COUNT(DISTINCT mg.company_id) > 5 THEN 'Diverse Production'
            ELSE 'Limited Production' 
        END AS production_type
    FROM 
        movie_graph mg
    GROUP BY 
        mg.movie_id, mg.title
),
title_info AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        ki.keyword AS keyword
    FROM 
        title
    LEFT JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
),
final_output AS (
    SELECT 
        a.movie_id,
        a.movie_title,
        a.company_count,
        a.company_names,
        a.production_type,
        ti.keyword
    FROM 
        aggregated_data a
    LEFT JOIN 
        title_info ti ON a.movie_id = ti.movie_id
    ORDER BY 
        a.company_count DESC, a.movie_title
)
SELECT 
    *,
    CASE 
        WHEN keyword IS NULL THEN 'No Keywords'
        ELSE keyword 
    END AS keyword_description
FROM 
    final_output
WHERE 
    production_type = 'Diverse Production'
    AND movie_title LIKE '%War%'
    OR movie_title LIKE '%Love%'
ORDER BY 
    movie_title ASC;
