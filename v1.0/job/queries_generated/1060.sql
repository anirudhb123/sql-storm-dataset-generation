WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
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
    HAVING 
        COUNT(DISTINCT mc.company_id) > 1
)
SELECT 
    r.title,
    r.production_year,
    r.actor_count,
    COALESCE(cc.company_count, 0) AS company_count,
    CASE 
        WHEN r.rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS rank_category
FROM 
    RankedMovies r
LEFT JOIN 
    CompanyCounts cc ON r.title_id = cc.movie_id
WHERE 
    r.production_year BETWEEN 2000 AND 2023
ORDER BY 
    r.production_year DESC, 
    r.actor_count DESC;
