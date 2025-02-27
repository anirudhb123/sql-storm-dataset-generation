WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        STRING_AGG(actor_name, ', ') AS actors 
    FROM 
        RankedMovies 
    WHERE 
        role_rank <= 3 
    GROUP BY 
        movie_id, title, production_year
),
KeywordInfo AS (
    SELECT 
        m.movie_id, 
        k.keyword 
    FROM 
        movie_keyword m 
    JOIN 
        keyword k ON m.keyword_id = k.id
),
MovieKeywords AS (
    SELECT 
        f.movie_id, 
        f.title,
        f.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies f
    LEFT JOIN 
        KeywordInfo k ON f.movie_id = k.movie_id
    GROUP BY 
        f.movie_id, f.title, f.production_year
)
SELECT 
    mk.movie_id,
    mk.title,
    mk.production_year,
    mk.actors,
    mk.keywords
FROM 
    FilteredMovies mk
WHERE 
    mk.production_year > 2000
ORDER BY 
    mk.production_year DESC, mk.title;
