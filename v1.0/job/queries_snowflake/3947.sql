
WITH RecursiveActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000 
    UNION ALL
    SELECT 
        a.id,
        a.name,
        c.movie_id,
        t.title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year < 2000
    AND 
        c.movie_id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%'))
),
TopMovies AS (
    SELECT 
        actor_id,
        actor_name,
        movie_id,
        movie_title,
        production_year,
        ROW_NUMBER() OVER (PARTITION BY actor_id ORDER BY production_year DESC) AS rn
    FROM 
        RecursiveActorMovies
),
ActorsWithMovies AS (
    SELECT
        actor_id,
        actor_name,
        movie_id,
        movie_title,
        production_year
    FROM 
        TopMovies
    WHERE 
        rn <= 5
),
MovieCompanyInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    GROUP BY 
        m.movie_id
)
SELECT 
    a.actor_name,
    a.movie_title,
    a.production_year,
    COALESCE(mc.companies, 'No companies') AS production_companies
FROM 
    ActorsWithMovies a
LEFT JOIN 
    MovieCompanyInfo mc ON a.movie_id = mc.movie_id
WHERE 
    a.production_year IS NOT NULL
ORDER BY 
    a.actor_name, a.production_year DESC;
