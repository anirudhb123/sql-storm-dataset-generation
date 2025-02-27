WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.id) AS rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvSeries'))
),
TopRankedMovies AS (
    SELECT 
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.rank = 1
),
ActorsMovies AS (
    SELECT 
        a.name AS actor_name,
        am.title,
        am.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        TopRankedMovies am ON ci.movie_id = am.movie_id
)
SELECT 
    am.actor_name,
    COUNT(am.title) AS movie_count,
    STRING_AGG(DISTINCT am.title, ', ') AS titles,
    CASE 
        WHEN COUNT(am.title) > 10 THEN 'Prolific Actor'
        WHEN COUNT(am.title) BETWEEN 5 AND 10 THEN 'Moderate Actor'
        ELSE 'Rare Actor'
    END AS actor_category
FROM 
    ActorsMovies am
GROUP BY 
    am.actor_name
HAVING 
    COUNT(am.title) > 0
ORDER BY 
    movie_count DESC;


