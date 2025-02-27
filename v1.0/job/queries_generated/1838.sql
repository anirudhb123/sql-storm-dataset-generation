WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year >= 2000
),
ActorMovieCounts AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        ca.person_id
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(kw.keywords, 'No keywords') AS keywords,
    ac.movie_count AS actor_movies,
    a.name AS actor_name,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY ac.movie_count DESC) AS actor_rank
FROM 
    RankedTitles t
LEFT JOIN 
    MoviesWithKeywords kw ON t.title_id = kw.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    ActorMovieCounts ac ON ci.person_id = ac.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
AND 
    ac.movie_count IS NOT NULL
ORDER BY 
    t.production_year, actor_rank;
