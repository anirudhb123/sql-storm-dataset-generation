WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_order,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY t.id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    COALESCE(NULLIF(md.cast_order, 0), 'No Cast') AS cast_position,
    md.company_count,
    CASE 
        WHEN md.production_year < 2000 THEN 'Old'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Recent'
        ELSE 'New'
    END AS production_category
FROM 
    MovieDetails md
WHERE 
    md.keyword IS NOT NULL
    AND md.company_count > 0
ORDER BY 
    md.production_year DESC, 
    md.title;
