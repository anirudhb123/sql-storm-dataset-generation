WITH MovieStats AS (
    SELECT 
        a.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        AVG(CASE WHEN tt.kind_id = 1 THEN 1 ELSE 0 END) AS is_feature_length,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        title t ON a.movie_id = t.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    LEFT JOIN 
        kind_type tt ON t.kind_id = tt.id
    WHERE 
        t.production_year IS NOT NULL AND
        t.production_year BETWEEN 1990 AND 2020
    GROUP BY 
        a.title, t.production_year
), TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        keywords,
        company_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rn
    FROM 
        MovieStats
)
SELECT 
    title,
    production_year,
    cast_count,
    keywords,
    company_count
FROM 
    TopMovies
WHERE 
    rn <= 5
ORDER BY 
    production_year DESC, cast_count DESC;
