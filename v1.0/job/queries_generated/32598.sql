WITH RECURSIVE RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieDetails AS (
    SELECT 
        m.title AS movie_title,
        m.production_year,
        COUNT(dc.id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        RankedMovies m
    LEFT JOIN 
        cast_info dc ON m.movie_id = dc.movie_id
    LEFT JOIN 
        aka_name a ON dc.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        m.rank <= 10
    GROUP BY 
        m.title, m.production_year
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        k.keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.actors,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    (SELECT 
        mk.movie_id, 
        STRING_AGG(mk.keyword, ', ') AS keywords
     FROM 
        MovieKeywords mk
     GROUP BY 
        mk.movie_id
    ) mk ON md.movie_id = mk.movie_id
WHERE 
    md.total_cast > 5
ORDER BY 
    md.production_year DESC, md.total_cast DESC;

In this SQL query, we perform performance benchmarking by leveraging several advanced SQL features:

1. **Common Table Expressions (CTEs)**: We use two CTEs - `RankedMovies` for ranking movies and `MovieDetails` for getting movie details, which reduces the data processing in the main query.

2. **Window Functions**: We use `ROW_NUMBER()` to rank movies by production year.

3. **Outer Joins**: We use `LEFT JOIN` to ensure we capture all movies and their associated data even if some records might not exist in the related tables.

4. **String Aggregation**: We utilize `STRING_AGG` to concatenate multiple actor names and company types into a single string, enhancing readability.

5. **Conditional Logic**: We include a `COALESCE` function to handle cases where a movie might not have keywords.

6. **Complicated Predicates**: We filter the results based on aggregate conditions, such as the total cast being greater than a fixed number (5).

7. **Subqueries**: We use a subquery to also aggregate keywords associated with movies.

This query is designed to benchmark the performance of complex queries involving joins, aggregations, and filtering logic on movie data.
