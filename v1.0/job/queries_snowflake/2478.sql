
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        tm.movie_id,
        tm.title,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id, tm.title
)
SELECT 
    mwk.movie_id,
    mwk.title,
    tm.production_year,
    CASE 
        WHEN mwk.keywords IS NULL THEN 'No keywords available'
        ELSE mwk.keywords
    END AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_actors
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    cast_info ci ON mwk.movie_id = ci.movie_id
LEFT JOIN 
    TopMovies tm ON mwk.movie_id = tm.movie_id
GROUP BY 
    mwk.movie_id, mwk.title, mwk.keywords, tm.production_year
ORDER BY 
    total_actors DESC,
    tm.production_year ASC;
