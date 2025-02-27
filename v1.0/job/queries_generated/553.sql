WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CountryStats AS (
    SELECT 
        c.country_code,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        AVG(m.production_year) AS avg_release_year
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        c.country_code
),
KeywordStats AS (
    SELECT 
        mk.keyword_id,
        COUNT(DISTINCT mk.movie_id) AS keyword_movie_count
    FROM 
        movie_keyword mk
    WHERE 
        mk.movie_id IN (SELECT id FROM aka_title WHERE production_year > 2000)
    GROUP BY 
        mk.keyword_id
)
SELECT 
    rm.title,
    rm.production_year,
    cs.country_code,
    cs.movie_count,
    cs.avg_release_year,
    ks.keyword_movie_count
FROM 
    RankedMovies rm
JOIN 
    CountryStats cs ON rm.production_year = cs.avg_release_year
LEFT JOIN 
    KeywordStats ks ON rm.production_year IN (SELECT DISTINCT m.production_year FROM movie_keyword mk JOIN aka_title m ON mk.movie_id = m.id)
WHERE 
    rm.movie_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    cs.movie_count DESC; 
