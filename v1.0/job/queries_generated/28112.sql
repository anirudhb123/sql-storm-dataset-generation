WITH RankedMovies AS (
    SELECT 
        tt.id AS movie_id,
        tt.title,
        tt.production_year,
        akn.name AS actor_name,
        RANK() OVER (PARTITION BY tt.production_year ORDER BY tt.production_year DESC) AS rank_by_year
    FROM 
        aka_title tt
    JOIN 
        cast_info ci ON tt.id = ci.movie_id
    JOIN 
        aka_name akn ON ci.person_id = akn.person_id
    WHERE 
        tt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND tt.production_year IS NOT NULL
),
KeywordStats AS (
    SELECT 
        mm.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        complete_cast cc ON mk.movie_id = cc.movie_id
    GROUP BY 
        mm.movie_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_name,
    ks.keyword_count,
    cs.company_count,
    CASE 
        WHEN rm.rank_by_year <= 5 THEN 'Top 5 of Year'
        ELSE 'Other'
    END AS ranking_category
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.rank_by_year;
