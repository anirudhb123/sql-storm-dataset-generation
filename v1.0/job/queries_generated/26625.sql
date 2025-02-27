WITH RankedTitles AS (
    SELECT 
        a.movie_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY a.movie_id ORDER BY a.id) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')
),
ActorInfo AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        COUNT(DISTINCT c.id) AS actor_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        RankedTitles t ON c.movie_id = t.movie_id
    GROUP BY 
        c.movie_id, p.name
),
MoviesWithInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ai.actor_name, 'No actors') AS actor_name,
        COALESCE(ai.actor_count, 0) AS actor_count,
        COALESCE(ai.titles, 'N/A') AS titles

    FROM 
        title m
    LEFT JOIN 
        ActorInfo ai ON m.id = ai.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
)
SELECT 
    *,
    CASE 
        WHEN actor_count = 0 THEN 'No Cast'
        WHEN actor_count < 3 THEN 'Few Actors'
        ELSE 'Many Actors'
    END AS cast_description
FROM 
    MoviesWithInfo
ORDER BY 
    production_year DESC, actor_count DESC;
