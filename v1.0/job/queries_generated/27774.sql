WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.title IS NOT NULL
        AND t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count
    FROM 
        RankedTitles
    GROUP BY 
        actor_name
    HAVING 
        COUNT(movie_title) > 3
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
)
SELECT 
    ac.actor_name,
    ac.movie_count,
    m.title AS movie_with_keywords,
    m.keywords
FROM 
    ActorCount ac
JOIN 
    RankedTitles rt ON ac.actor_name = rt.actor_name
JOIN 
    MoviesWithKeywords m ON rt.movie_title = m.title
WHERE 
    rt.year_rank <= 5
ORDER BY 
    ac.movie_count DESC, m.title;
