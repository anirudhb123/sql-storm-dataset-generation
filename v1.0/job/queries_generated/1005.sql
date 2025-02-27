WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_of_movie
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStatistics AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cs.company_count, 0) AS total_companies,
    COALESCE(ks.keyword_count, 0) AS total_keywords,
    rm.rank_of_movie
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStatistics cs ON rm.movie_id = cs.movie_id
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
WHERE 
    rm.rank_of_movie <= 5
ORDER BY 
    rm.production_year DESC, rm.rank_of_movie;
