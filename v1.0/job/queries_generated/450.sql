WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    am.actor_id,
    am.actor_name,
    COUNT(DISTINCT am.movie_id) AS movies_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    rt.production_year,
    rt.title
FROM 
    ActorMovies am
JOIN 
    RankedTitles rt ON am.title = rt.title AND rt.year_rank = 1
LEFT JOIN 
    MovieKeywords mk ON am.movie_id = mk.movie_id
WHERE 
    am.production_year BETWEEN 2000 AND 2020
GROUP BY 
    am.actor_id, am.actor_name, mk.keywords, rt.production_year, rt.title
HAVING 
    COUNT(DISTINCT am.movie_id) > 5
ORDER BY 
    movies_count DESC,
    rt.production_year ASC;
