
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title, t.production_year
),
HighestActors AS (
    SELECT 
        production_year, title
    FROM 
        RankedMovies
    WHERE 
        rank = 1
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    h.title AS highest_actor_title,
    h.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    LEFT(h.title, 10) || '...' AS short_title,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = h.title LIMIT 1)) AS info_count
FROM 
    HighestActors h
LEFT JOIN 
    MovieKeywords mk ON h.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
WHERE 
    h.production_year IS NOT NULL
ORDER BY 
    h.production_year DESC;
