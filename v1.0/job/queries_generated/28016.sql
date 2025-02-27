WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        ak.name AS actor_name,
        ak.imdb_index AS actor_index,
        ci.nr_order AS actor_order
    FROM 
        RankedMovies m
    JOIN 
        complete_cast cc ON cc.movie_id = m.movie_id
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id AND ci.nr_order IS NOT NULL
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE
        m.rank_by_title <= 10 -- Top 10 movies per production year
),
MovieKeywords AS (
    SELECT 
        fm.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies fm
    JOIN 
        movie_keyword mk ON mk.movie_id = fm.movie_id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        fm.movie_id
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_name,
    fm.actor_index,
    mf.keywords
FROM 
    FilteredMovies fm
JOIN 
    MovieKeywords mf ON mf.movie_id = fm.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.actor_order;

This query performs the following:

1. **RankedMovies CTE**: It ranks movies by their title for each production year, filtering out movies without a production year.
2. **FilteredMovies CTE**: It retrieves the top 10 movies per production year, including associated actor details.
3. **MovieKeywords CTE**: It gathers all keywords associated with these movies, aggregating them into a single string per movie.
4. **Final Selection**: It selects relevant movie, actor, and keyword details, ordering by production year and actor order for a clear presentation.
