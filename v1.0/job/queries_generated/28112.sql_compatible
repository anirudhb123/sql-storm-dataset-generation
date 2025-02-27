
WITH RankedMovies AS (
    SELECT 
        tt.id AS movie_id,
        tt.title,
        tt.production_year,
        akn.name AS actor_name,
        RANK() OVER (PARTITION BY tt.production_year ORDER BY tt.production_year DESC) AS rank_by_year
    FROM 
        aka_title AS tt
    JOIN 
        cast_info AS ci ON tt.id = ci.movie_id
    JOIN 
        aka_name AS akn ON ci.person_id = akn.person_id
    WHERE 
        tt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND tt.production_year IS NOT NULL
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    JOIN 
        complete_cast AS cc ON mk.movie_id = cc.movie_id
    GROUP BY 
        mk.movie_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    COALESCE(cs.company_count, 0) AS company_count,
    CASE 
        WHEN rm.rank_by_year <= 5 THEN 'Top 5 of Year'
        ELSE 'Other'
    END AS ranking_category
FROM 
    RankedMovies AS rm
LEFT JOIN 
    KeywordStats AS ks ON rm.movie_id = ks.movie_id
LEFT JOIN 
    CompanyStats AS cs ON rm.movie_id = cs.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.rank_by_year;
