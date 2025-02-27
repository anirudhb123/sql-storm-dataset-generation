WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MoviesWithGenres AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.actor_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year, tm.actor_count
)
SELECT 
    mwg.title,
    mwg.production_year,
    mwg.actor_count,
    COALESCE(mwg.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mwg.actor_count >= 5 THEN 'Blockbuster'
        WHEN mwg.actor_count BETWEEN 1 AND 4 THEN 'Indie'
        ELSE 'Unknown'
    END AS movie_category
FROM 
    MoviesWithGenres mwg
WHERE 
    mwg.production_year >= 2000
ORDER BY 
    mwg.production_year DESC, mwg.actor_count DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
