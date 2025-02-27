WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM 
        title t
),
ActorCounts AS (
    SELECT
        a.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        a.person_id
),
TopActors AS (
    SELECT 
        ac.person_id
    FROM 
        ActorCounts ac
    WHERE 
        ac.movie_count > (
            SELECT AVG(movie_count) FROM ActorCounts
        )
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(t.production_year) OVER () AS max_production_year
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    (CASE 
        WHEN md.production_year = md.max_production_year THEN 'Latest Release'
        ELSE 'Older Release'
     END) AS release_status,
    (SELECT STRING_AGG(a.name, ', ') 
     FROM aka_name a 
     WHERE a.person_id IN (SELECT person_id FROM TopActors)
     AND EXISTS (SELECT 1 FROM cast_info ci WHERE ci.person_id = a.person_id AND ci.movie_id = md.movie_id)) AS top_actors
FROM 
    MovieDetails md 
WHERE 
    md.production_year > (SELECT MIN(production_year) FROM MovieDetails) 
    AND md.total_cast IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
