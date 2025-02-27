
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
NotableActors AS (
    SELECT 
        a.name,
        COUNT(ci.id) AS movie_count,
        SUM(CASE WHEN ci.person_role_id IS NULL THEN 1 ELSE 0 END) AS uncredited_count,
        MAX(a.id) AS actor_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(ci.id) > 5
),
CompanyDetails AS (
    SELECT 
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.movie_id) AS produced_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        c.name, ct.kind
    HAVING 
        COUNT(mc.movie_id) > 3
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        na.name AS actor_name,
        cd.company_name,
        cd.company_type,
        na.movie_count,
        na.uncredited_count,
        rm.year_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        NotableActors na ON na.movie_count = (
            SELECT MAX(movie_count) FROM NotableActors)
    LEFT JOIN 
        (SELECT DISTINCT mc.movie_id, cn.name AS company_name, ct.kind AS company_type 
         FROM movie_companies mc 
         JOIN company_name cn ON mc.company_id = cn.id 
         JOIN company_type ct ON mc.company_type_id = ct.id) cd 
    ON 
        cd.movie_id = rm.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    COALESCE(fr.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(fr.company_name, 'Independent') AS company_name,
    COALESCE(fr.company_type, 'N/A') AS company_type,
    fr.movie_count,
    fr.uncredited_count,
    fr.year_rank
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.year_rank;
