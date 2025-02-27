WITH movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id, k.keyword
), detailed_cast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
), benchmark_results AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.cast_count,
        dc.person_id,
        dc.role,
        dc.role_order
    FROM 
        movie_details md
    LEFT JOIN 
        detailed_cast dc ON md.movie_id = dc.movie_id
    WHERE 
        md.production_year >= 2000
        AND md.cast_count > 5
    ORDER BY 
        md.production_year DESC, md.title
), final_results AS (
    SELECT
        br.movie_id,
        br.title,
        br.production_year,
        br.keyword,
        br.cast_count,
        COALESCE(br.role, 'Unknown Role') AS role,
        CASE 
            WHEN br.role_order IS NULL THEN 0
            ELSE br.role_order
        END AS role_order
    FROM 
        benchmark_results br
    WHERE 
        br.role IS NOT NULL OR br.cast_count > 10
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.keyword,
    fr.cast_count,
    fr.role,
    fr.role_order,
    CASE 
        WHEN fr.cast_count > 20 THEN 'Highly Cast'
        WHEN fr.cast_count BETWEEN 10 AND 20 THEN 'Moderately Cast'
        ELSE 'Sparsely Cast'
    END AS cast_classification
FROM 
    final_results fr
WHERE 
    fr.production_year = (SELECT MAX(production_year) FROM final_results)
    OR fr.role = 'Lead'
ORDER BY 
    cast_classification DESC, fr.title;
