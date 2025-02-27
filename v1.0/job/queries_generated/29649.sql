WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
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
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        actor_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.actor_names,
    fm.keywords
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 10
ORDER BY 
    fm.cast_count DESC, 
    fm.production_year DESC;
