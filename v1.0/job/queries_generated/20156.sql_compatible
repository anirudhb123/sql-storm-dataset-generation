
WITH RecursiveActorStats AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(t.production_year) AS avg_production_year,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL AND a.name <> ''
    GROUP BY 
        a.person_id, a.name
),
TopActors AS (
    SELECT 
        person_id, 
        name, 
        actor_rank 
    FROM 
        RecursiveActorStats 
    WHERE 
        actor_rank <= 10
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        CASE 
            WHEN m.production_year IS NULL THEN 'Unknown Year'
            ELSE CAST(m.production_year AS VARCHAR) 
        END AS production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    ta.name AS actor_name,
    md.title AS movie_title,
    md.production_year,
    COALESCE(md.keywords, 'None') AS keywords,
    CASE 
        WHEN md.production_year IS NULL THEN 'Production Year Missing'
        ELSE 'Production Year Present'
    END AS year_status
FROM 
    TopActors ta
LEFT JOIN 
    cast_info c ON ta.person_id = c.person_id
LEFT JOIN 
    MovieDetails md ON c.movie_id = md.movie_id
WHERE 
    ta.actor_rank = 1 OR md.production_year IS NOT NULL
ORDER BY 
    ta.actor_rank, md.title;
