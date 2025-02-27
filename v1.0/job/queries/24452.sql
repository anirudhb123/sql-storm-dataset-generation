
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.actor_count,
        ARRAY_AGG(DISTINCT a.name) AS actors,
        (SELECT MIN(CASE WHEN mo.production_year IS NOT NULL THEN mo.production_year ELSE 9999 END)
         FROM aka_title mo 
         WHERE mo.production_year >= r.production_year) AS next_movie_year
    FROM 
        RankedMovies r
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        r.rank <= 5 
    GROUP BY 
        r.movie_id, r.title, r.production_year, r.actor_count
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.actors,
    CASE 
        WHEN md.next_movie_year IS NULL THEN 'No subsequent movie found'
        WHEN md.next_movie_year = 9999 THEN 'Future prediction'
        ELSE CAST(md.next_movie_year - md.production_year AS TEXT) || ' years until next movie'
    END AS next_movie_analysis
FROM 
    MovieDetails md
WHERE 
    md.actor_count > 3
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC;
