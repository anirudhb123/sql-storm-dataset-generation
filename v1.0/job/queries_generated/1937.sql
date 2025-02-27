WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyCount AS (
    SELECT 
        m.movie_id,
        COUNT(mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.total_cast,
    COALESCE(cc.company_count, 0) AS company_count,
    CASE 
        WHEN rm.total_cast > 50 THEN 'Highly Featured'
        WHEN rm.total_cast BETWEEN 20 AND 50 THEN 'Moderately Featured'
        ELSE 'Featured Less'
    END AS cast_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyCount cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
