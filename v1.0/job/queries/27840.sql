WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT * 
    FROM RankedMovies 
    WHERE rank <= 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_names,
    ARRAY_LENGTH(fm.keywords, 1) AS keyword_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.title;
