WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
HighestCastedActor AS (
    SELECT 
        ac.person_id
    FROM 
        ActorMovieCount ac
    WHERE 
        ac.movie_count = (SELECT MAX(movie_count) FROM ActorMovieCount)
),
MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        ak.name AS actor_name,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    WHERE 
        ci.person_id IN (SELECT person_id FROM HighestCastedActor)
    GROUP BY 
        mt.title, mt.production_year, ak.name
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    md.company_count,
    rt.title_rank
FROM 
    MovieDetails md
JOIN 
    RankedTitles rt ON md.title = rt.title AND md.production_year = rt.production_year
WHERE 
    md.company_count > 2 
ORDER BY 
    md.production_year DESC, md.company_count DESC;
