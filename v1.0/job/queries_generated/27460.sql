WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT ca.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        t.id
),

TitleStats AS (
    SELECT
        movie_id,
        title,
        production_year,
        CAST_COUNT,
        CASE 
            WHEN CAST_COUNT < 3 THEN 'Low'
            WHEN CAST_COUNT BETWEEN 3 AND 10 THEN 'Medium'
            ELSE 'High'
        END AS cast_size_category
    FROM 
        MovieDetails
)

SELECT 
    ts.title,
    ts.production_year,
    ts.cast_size_category,
    ts.cast_count,
    md.keywords
FROM 
    TitleStats ts
LEFT JOIN 
    MovieDetails md ON ts.movie_id = md.movie_id
WHERE 
    ts.production_year >= 2000
ORDER BY 
    ts.production_year DESC, 
    ts.cast_count DESC;
