WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieWithKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
DetailedCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COALESCE(mw.keywords, 'No keywords') AS keywords
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        MovieWithKeywords mw ON c.movie_id = mw.movie_id
),
MovieSummaries AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        dc.actor_name,
        dc.role_name,
        COUNT(dc.actor_name) OVER (PARTITION BY r.title_id) AS actor_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        DetailedCast dc ON r.title_id = dc.movie_id
)
SELECT 
    ms.title,
    ms.production_year,
    ms.actor_name,
    ms.role_name,
    ms.actor_count,
    COUNT(*) OVER () AS total_titles
FROM 
    MovieSummaries ms
WHERE 
    ms.actor_count > 1 OR ms.role_name LIKE '%lead%'
ORDER BY 
    ms.production_year DESC, 
    ms.title;
