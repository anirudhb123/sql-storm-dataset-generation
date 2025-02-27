WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.name, t.title, t.production_year
),
MovieKeywords AS (
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
FilteredMovies AS (
    SELECT 
        rm.actor_name,
        rm.movie_title,
        rm.production_year,
        mk.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_title = mk.movie_id
    WHERE 
        rm.actor_rank <= 5
)
SELECT 
    fm.actor_name,
    fm.movie_title,
    COALESCE(fm.keywords, 'No keywords available') AS keywords,
    CASE 
        WHEN fm.production_year IS NULL THEN 'Year unknown'
        ELSE fm.production_year::text 
    END AS production_year,
    COUNT(DISTINCT c.person_id) AS total_cast
FROM 
    FilteredMovies fm
LEFT JOIN 
    cast_info c ON fm.movie_title = c.movie_id
GROUP BY 
    fm.actor_name, 
    fm.movie_title, 
    fm.keywords, 
    fm.production_year
ORDER BY 
    fm.actor_name, 
    fm.production_year DESC;
