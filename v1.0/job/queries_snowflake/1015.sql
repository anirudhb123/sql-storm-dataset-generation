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
ActorsInMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc 
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    RM.movie_id,
    RM.title,
    RM.production_year,
    A.actor_name,
    COALESCE(CMC.company_count, 0) AS companies_involved,
    A.actor_count,
    CASE 
        WHEN A.actor_count > 5 THEN 'Major Cast'
        WHEN A.actor_count BETWEEN 3 AND 5 THEN 'Supporting Cast'
        ELSE 'Minor Cast'
    END AS cast_size,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = RM.movie_id AND mi.info_type_id IN 
         (SELECT id FROM info_type WHERE info = 'Box Office')) AS box_office_info
FROM 
    RankedMovies RM
LEFT JOIN 
    ActorsInMovies A ON RM.movie_id = A.movie_id
LEFT JOIN 
    CompanyMovieCount CMC ON RM.movie_id = CMC.movie_id
WHERE 
    RM.year_rank <= 10
ORDER BY 
    RM.production_year DESC, RM.title;
