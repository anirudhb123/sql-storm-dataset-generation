WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title AS mt
    JOIN 
        cast_info AS ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cmp.company_id) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cmp ON mc.company_id = cmp.id
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        cmc.company_count
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        CompanyMovieCount AS cmc ON rm.movie_title = (SELECT title FROM aka_title WHERE id = cmc.movie_id)
    WHERE 
        rm.rank_per_year <= 5
)
SELECT 
    m.movie_title,
    m.production_year,
    m.actor_count,
    COALESCE(m.company_count, 0) AS company_count,
    CASE 
        WHEN m.actor_count > 10 THEN 'Many actors'
        WHEN m.actor_count IS NULL THEN 'No actors'
        ELSE 'Few actors'
    END AS actor_status
FROM 
    TopMovies AS m
ORDER BY 
    m.production_year DESC, m.actor_count DESC
LIMIT 10;
