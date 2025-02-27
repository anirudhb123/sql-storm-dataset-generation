WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsWithMovies AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        k.keyword,
        COALESCE(NULLIF(SUBSTRING(m.title FROM '^(.*\s+){0,3}'), ''), 'No Keywords') AS relevant_keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    at.actor_name,
    rt.title,
    rt.production_year,
    mk.keyword,
    mk.relevant_keywords,
    COALESCE(NULLIF(mk.relevant_keywords, ''), 'None') AS keyword_status,
    SUM(rt.title_rank) OVER (PARTITION BY at.actor_name) AS total_rank_score
FROM 
    ActorsWithMovies at
JOIN 
    RankedTitles rt ON at.movie_count > 5 AND at.movie_titles LIKE '%' || rt.title || '%'
LEFT JOIN 
    MoviesWithKeywords mk ON rt.title_id = mk.movie_id
WHERE 
    mk.keyword IS NOT NULL
ORDER BY 
    at.actor_name, rt.production_year DESC;
