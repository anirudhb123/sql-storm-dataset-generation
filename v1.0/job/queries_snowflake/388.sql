
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
HighRatingMovies AS (
    SELECT 
        t.movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        RankedMovies t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.rank <= 10
    GROUP BY 
        t.movie_id, t.title, t.production_year
),
CompanyCount AS (
    SELECT 
        m.movie_id, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    hc.movie_id, 
    hc.title, 
    hc.production_year, 
    COALESCE(cc.company_count, 0) AS company_count, 
    hc.keyword_count
FROM 
    HighRatingMovies hc
LEFT JOIN 
    CompanyCount cc ON hc.movie_id = cc.movie_id
ORDER BY 
    hc.production_year DESC, 
    hc.keyword_count DESC
LIMIT 20;
