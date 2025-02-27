WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        cast_count,
        actor_names,
        keywords,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    km.kind AS kind_type,
    fm.cast_count,
    fm.actor_names,
    fm.keywords
FROM 
    FilteredMovies fm
JOIN 
    kind_type km ON fm.kind_id = km.id
WHERE 
    fm.rank <= 5
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;

This SQL query benchmarks string processing features by aggregating and ranking movie titles based on their associated cast members and keywords, providing a detailed view of the most prominent movies for each production year.
