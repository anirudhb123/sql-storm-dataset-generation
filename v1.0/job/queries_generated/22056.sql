WITH movie_ranking AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        AVG(COALESCE(mi.info::numeric, 0)) AS avg_info_length,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id
    WHERE 
        mt.production_year IS NOT NULL
        AND (mt.note IS NULL OR mt.note NOT LIKE '%uncategorized%')
    GROUP BY 
        mt.id, mt.title
),
top_movies AS (
    SELECT movie_id, title, rank, cast_count, avg_info_length
    FROM movie_ranking
    WHERE rank <= 10
),
creator_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        cn.name IS NOT NULL
    GROUP BY mc.movie_id
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.cast_count,
        tm.avg_info_length,
        ci.company_names,
        ci.company_types
    FROM 
        top_movies tm
    LEFT JOIN 
        creator_info ci ON tm.movie_id = ci.movie_id
)
SELECT 
    md.title,
    md.cast_count,
    md.avg_info_length,
    COALESCE(md.company_names, 'No Companies') AS company_names,
    CASE 
        WHEN md.company_types IS NULL THEN 'Unknown'
        WHEN md.company_types > 10 THEN 'Diverse Company Types'
        ELSE md.company_types::text 
    END AS company_type_count,
    CASE 
        WHEN md.avg_info_length > 50 THEN 'Excessive Info Length'
        WHEN md.avg_info_length IS NULL THEN 'No Info Available'
        ELSE 'Normal Info Length'
    END AS info_length_description
FROM 
    movie_details md
WHERE 
    (md.cast_count > 0 OR md.company_types > 0)
ORDER BY 
    md.cast_count DESC,
    md.avg_info_length ASC;

