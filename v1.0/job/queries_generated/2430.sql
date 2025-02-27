WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM
        aka_title t
    WHERE
        t.production_year >= 2000
),
ActorsMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        c.nr_order
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        aka_title t ON c.movie_id = t.id
    WHERE
        c.nr_order IS NOT NULL
),
AggregatedInfo AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_title) AS movie_count,
        AVG(CASE WHEN production_year IS NOT NULL THEN production_year ELSE 0 END) AS avg_production_year
    FROM 
        ActorsMovies
    GROUP BY 
        actor_name
),
TheatricalReleases AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        movie_id
)
SELECT 
    a.actor_name,
    COALESCE(ai.movie_count, 0) AS total_movies,
    COALESCE(ai.avg_production_year, 0) AS average_year,
    COALESCE(tr.keywords, 'No Keywords') AS associated_keywords
FROM 
    aka_name a
LEFT JOIN 
    AggregatedInfo ai ON a.name = ai.actor_name
LEFT JOIN 
    ActorsMovies am ON a.id = am.actor_name
LEFT JOIN 
    TheatricalReleases tr ON am.movie_title = tr.movie_id
WHERE 
    a.id IN (SELECT DISTINCT person_id FROM cast_info WHERE movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000))
ORDER BY 
    total_movies DESC, average_year DESC
LIMIT 10;
