WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL), '{}') AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
company_info AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.cast_count,
        ci.companies,
        ci.company_count,
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank_by_cast
    FROM 
        movie_data md
    LEFT JOIN 
        company_info ci ON md.movie_id = ci.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.company_count,
    rm.keywords,
    CASE 
        WHEN rm.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_status
FROM 
    ranked_movies rm
WHERE 
    rm.rank_by_cast <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
