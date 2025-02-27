WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(mr.info :: NUMERIC) AS avg_rating,
        RANK() OVER (PARTITION BY t.production_year ORDER BY AVG(mr.info :: NUMERIC) DESC) AS rating_rank
    FROM 
        title t
    LEFT JOIN 
        movie_info mr ON t.id = mr.movie_id AND mr.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.avg_rating
    FROM 
        RankedMovies rm
    WHERE 
        rm.rating_rank <= 10
)
SELECT 
    COALESCE(c.name, 'Unknown') AS company_name,
    tm.title,
    tm.production_year,
    tm.avg_rating,
    tc.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    company_type tc ON mc.company_type_id = tc.id
WHERE 
    (tm.avg_rating IS NOT NULL AND tm.company_count > 0)
    OR (tm.avg_rating IS NULL AND tm.company_count IS NOT NULL)
ORDER BY 
    tm.production_year DESC, 
    tm.avg_rating DESC;
