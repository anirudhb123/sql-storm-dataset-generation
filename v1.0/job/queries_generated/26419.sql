WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(DISTINCT mc.company_id) AS production_companies_count,
        COUNT(DISTINCT mk.keyword_id) AS keywords_count,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.actors,
        rm.production_companies_count,
        rm.keywords_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    kt.kind AS movie_kind,
    fm.actors,
    fm.production_companies_count,
    fm.keywords_count
FROM 
    FilteredMovies fm
JOIN 
    kind_type kt ON fm.kind_id = kt.id
ORDER BY 
    fm.production_year DESC, fm.title;

This query first creates a Common Table Expression (CTE) called `RankedMovies`, which retrieves movie details starting from the year 2000, aggregates actor names, counts production companies, and counts keywords associated with each movie. It ranks the movies by kind and production year.

The second CTE, `FilteredMovies`, filters these ranked movies, extracting only the top 5 movies per kind.

Finally, the main query retrieves the movie ID, title, production year, movie kind, actors, the count of production companies, and the count of keywords, sorting the results by production year in descending order and then by title.
