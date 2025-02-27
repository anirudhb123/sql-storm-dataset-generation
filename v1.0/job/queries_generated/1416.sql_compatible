
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
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword_list, 'No Keywords') AS keywords,
        m.actor_count
    FROM 
        RankedMovies m
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keyword_list
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) AS k ON m.movie_id = k.movie_id
),
FilteredMovies AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.production_year,
        mw.keywords,
        mw.actor_count
    FROM 
        MoviesWithKeywords mw
    WHERE 
        mw.production_year >= 2000 AND mw.actor_count > 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.keywords,
    CASE 
        WHEN f.production_year IS NULL THEN 'Unknown Year'
        ELSE 'Released in ' || CAST(f.production_year AS VARCHAR)
    END AS release_statement,
    CASE 
        WHEN EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = f.movie_id AND cc.status_id IS NULL) 
        THEN 'Incomplete Cast'
        ELSE 'Complete Cast'
    END AS cast_status
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, f.title;
