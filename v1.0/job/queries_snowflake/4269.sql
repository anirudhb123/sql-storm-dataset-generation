WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
CompanyMovieCounts AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
)
SELECT 
    a.name AS actor_name,
    r.title AS movie_title,
    r.production_year,
    COALESCE(ac.movie_count, 0) AS total_movies_as_actor,
    COALESCE(cc.movie_count, 0) AS total_movies_by_company,
    CASE 
        WHEN r.year_rank <= 5 THEN 'Top 5 Movies of Year'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies r
LEFT JOIN 
    cast_info c ON r.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    ActorMovieCounts ac ON c.person_id = ac.person_id
LEFT JOIN 
    CompanyMovieCounts cc ON mc.company_id = cc.company_id
WHERE 
    a.name IS NOT NULL
    AND (r.production_year > 2000 OR r.production_year IS NULL)
ORDER BY 
    r.production_year DESC, 
    a.name;
