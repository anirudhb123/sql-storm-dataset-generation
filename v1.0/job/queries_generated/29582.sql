WITH concatenated_titles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        STRING_AGG(a.title, ', ') AS all_titles,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ca ON ca.movie_id = a.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
company_details AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
),
final_benchmark AS (
    SELECT 
        ct.title_id,
        ct.title,
        ct.production_year,
        ct.all_titles,
        ct.cast_count,
        co.company_names,
        co.company_type,
        RANK() OVER (PARTITION BY ct.production_year ORDER BY ct.cast_count DESC) AS rank_by_cast_count
    FROM 
        concatenated_titles ct
    LEFT JOIN 
        company_details co ON ct.title_id = co.movie_id
)
SELECT 
    *
FROM 
    final_benchmark
WHERE 
    rank_by_cast_count <= 5
ORDER BY 
    production_year DESC, cast_count DESC;
