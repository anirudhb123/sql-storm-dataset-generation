
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
RecentMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.actor_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year = (SELECT MAX(production_year) FROM aka_title)
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        k.keyword
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
)
SELECT 
    r.title,
    r.production_year,
    r.actor_count,
    COALESCE(GROUP_CONCAT(DISTINCT kw.keyword), 'No keywords') AS keywords
FROM 
    RecentMovies r
LEFT JOIN 
    MoviesWithKeywords mw ON r.title = (SELECT title FROM aka_title WHERE id = mw.movie_id)
LEFT JOIN 
    keyword kw ON mw.keyword = kw.keyword
GROUP BY 
    r.title, r.production_year, r.actor_count
HAVING 
    r.actor_count > (SELECT AVG(actor_count) FROM RankedMovies)
ORDER BY 
    r.actor_count DESC;
