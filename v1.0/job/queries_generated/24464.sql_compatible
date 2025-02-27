
WITH RecursiveActorTitles AS (
    SELECT 
        a.id AS actor_id,
        a.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank,
        t.id AS movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND a.name <> ''
),
TitleStatistics AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actor_id) AS total_actors,
        SUM(CASE WHEN title_rank <= 3 THEN 1 ELSE 0 END) AS top_3_actor_count
    FROM 
        RecursiveActorTitles
    GROUP BY 
        movie_id
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(ts.total_actors, 0) AS total_actors,
        COALESCE(ts.top_3_actor_count, 0) AS top_3_actors
    FROM 
        aka_title t
    LEFT JOIN 
        TitleStatistics ts ON t.id = ts.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_actors,
    md.top_3_actors,
    COALESCE(NULLIF(md.title, ''), 'Unknown Title') AS safe_title,
    ROUND((md.total_actors * 1.0) / NULLIF(md.top_3_actors, 0), 2) AS actor_ratio,
    CASE 
        WHEN md.total_actors = 0 THEN 'No Actors'
        WHEN md.top_3_actors = 0 THEN 'Top actors not present'
        ELSE 'Active cast presence'
    END AS actor_presence
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    actor_ratio DESC
LIMIT 100
OFFSET 0;
