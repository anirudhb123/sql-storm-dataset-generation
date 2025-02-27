WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyCounts AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(cc.company_count, 0) AS company_count,
    CASE 
        WHEN rm.cast_count > 10 THEN 'Large Cast'
        WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    (SELECT STRING_AGG(DISTINCT a.name, ', ') 
     FROM aka_name a 
     JOIN cast_info ci ON a.person_id = ci.person_id 
     WHERE ci.movie_id = rm.title_id) AS cast_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyCounts cc ON rm.title_id = cc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, cast_count DESC;
