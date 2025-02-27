WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 1990 AND 2020
),
TopRanked AS (
    SELECT 
        rt.title_id,
        rt.title
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 5
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.title,
        COALESCE(am.actor_count, 0) AS actor_count,
        m.production_year,
        CASE 
            WHEN am.actor_count IS NULL THEN 'No actors'
            ELSE 'Has actors'
        END AS actor_status
    FROM 
        aka_title m
    LEFT JOIN 
        ActorMovies am ON m.id = am.movie_id
    WHERE 
        m.production_year >= 2000
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.actor_status,
    k.keyword
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.title = (SELECT title FROM aka_title WHERE id = md.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    md.actor_count > 3
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC
LIMIT 10;
