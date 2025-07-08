WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
HighActorMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_count > 5
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
)
SELECT 
    H.title,
    H.production_year,
    COALESCE(CC.company_count, 0) AS companies_involved
FROM 
    HighActorMovies H
LEFT JOIN 
    CompanyCounts CC ON H.title = (SELECT title FROM aka_title WHERE id = CC.movie_id)
WHERE 
    H.production_year > 2000
ORDER BY 
    H.production_year DESC, H.title;
