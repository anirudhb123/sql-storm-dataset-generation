
WITH MovieRankings AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyContribution AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        mr.movie_title, 
        mr.production_year, 
        mr.cast_count,
        COALESCE(cc.company_count, 0) AS company_count
    FROM 
        MovieRankings mr
    LEFT JOIN 
        CompanyContribution cc ON mr.movie_title = (SELECT title FROM aka_title a WHERE a.id = cc.movie_id)
    WHERE 
        mr.rank <= 10
)
SELECT 
    t.movie_title, 
    t.production_year, 
    t.cast_count,
    t.company_count,
    CASE 
        WHEN t.company_count > 0 THEN 'Produced'
        ELSE 'Independent'
    END AS production_type
FROM 
    TopMovies t
ORDER BY 
    t.production_year DESC, t.cast_count DESC;
