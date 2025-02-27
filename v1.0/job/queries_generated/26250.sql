WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        kt.kind AS type,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
ActorsAndMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        am.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts am ON a.person_id = am.person_id
    WHERE 
        am.movie_count > 5  -- Consider actors appearing in more than 5 movies
),
TitleDetails AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        a.actor_name,
        a.actor_id
    FROM 
        RankedTitles rt
    JOIN 
        cast_info ci ON rt.title_id = ci.movie_id
    JOIN 
        ActorsAndMovies a ON ci.person_id = a.actor_id
)
SELECT 
    td.title,
    td.production_year,
    td.actor_name,
    COUNT(DISTINCT c.party_id) AS unique_companies,
    STRING_AGG(DISTINCT c.name, ', ') AS company_names
FROM 
    TitleDetails td
LEFT JOIN 
    movie_companies mc ON td.title_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
GROUP BY 
    td.title,
    td.production_year,
    td.actor_name
ORDER BY 
    td.production_year DESC, 
    td.title;
