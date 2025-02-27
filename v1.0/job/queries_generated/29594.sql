WITH keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        COALESCE(STRING_AGG(DISTINCT c.name, ', '), 'No Cast') AS cast_names
    FROM 
        title m
    LEFT JOIN 
        keyword_counts kc ON m.id = kc.movie_id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year, kc.keyword_count
),
company_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
final_benchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword_count,
        cd.company_names,
        cd.company_types,
        md.cast_names
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    *,
    CASE 
        WHEN keyword_count > 5 THEN 'Highly Tagged'
        WHEN keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
        ELSE 'Low Tag Count'
    END AS tagging_category
FROM 
    final_benchmark
ORDER BY 
    production_year DESC, keyword_count DESC;
