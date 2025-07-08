
WITH RecursiveActorMovies AS (
    SELECT 
        ca.person_id,
        a.name AS actor_name,
        COUNT(DISTINCT m.id) AS movie_count,
        SUM(m.production_year) AS total_production_years,
        LISTAGG(DISTINCT m.title, ', ') WITHIN GROUP (ORDER BY m.title) AS movie_titles
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    INNER JOIN 
        aka_title m ON ca.movie_id = m.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        ca.person_id, a.name
),
TopActors AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        RecursiveActorMovies
),
CompanyMovieDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS total_companies,
        SUM(CASE WHEN co.country_code IS NULL THEN 1 ELSE 0 END) AS null_country_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
FinalActorDetails AS (
    SELECT 
        ta.actor_name,
        ta.movie_count,
        ta.total_production_years,
        ta.movie_titles,
        cmd.total_companies,
        cmd.null_country_count
    FROM 
        TopActors ta
    LEFT JOIN 
        CompanyMovieDetails cmd ON ta.movie_count = cmd.total_companies
    WHERE 
        ta.rank <= 10 AND 
        ta.total_production_years > 2000
)
SELECT 
    fad.actor_name,
    fad.movie_count,
    fad.total_production_years,
    fad.movie_titles,
    COALESCE(fad.null_country_count, 0) AS null_country_count,
    CASE 
        WHEN fad.movie_count > 5 THEN 'Prolific Actor'
        WHEN fad.null_country_count > 0 THEN 'Some companies have no country'
        ELSE 'Average Actor'
    END AS actor_status
FROM 
    FinalActorDetails fad
WHERE 
    fad.movie_titles LIKE '%Mystery%' 
ORDER BY 
    fad.movie_count DESC, fad.actor_name;
