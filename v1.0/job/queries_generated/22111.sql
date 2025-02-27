WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS cast_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        cast_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS movie_keyword,
        COALESCE(ci.kind, 'Unknown') AS company_kind,
        COUNT(DISTINCT ci.company_id) AS associated_companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_type ci ON mc.company_type_id = ci.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, mk.keyword, ci.kind
),
DetailedCast AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT ak.name ORDER BY ak.name) AS cast_names,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.movie_keyword,
    md.company_kind,
    md.associated_companies,
    dc.cast_names,
    dc.note_count
FROM 
    MovieDetails md
LEFT JOIN 
    DetailedCast dc ON md.movie_id = dc.movie_id
WHERE 
    md.associated_companies >= 2
    AND (md.production_year IS NULL OR md.production_year > 2000)
ORDER BY 
    md.production_year DESC, 
    md.associated_companies DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

This SQL query consists of several components:

1. **Common Table Expressions (CTEs)**: 
   - `RankedMovies` ranks movies by the number of distinct cast members per production year.
   - `TopMovies` filters to only include the top 5 ranked movies.
   - `MovieDetails` aggregates movie details including keywords and company information.
   - `DetailedCast` gathers a list of cast names and counts non-null notes per movie.

2. **Left Joins**: Included to ensure that all movies are returned even if they might not have associated data in the joined tables.

3. **Aggregations and Array Functions**: COUNT, ARRAY_AGG, and COALESCE functions are used extensively for summarizing data and handling NULLs.

4. **Complex Filtering**: The final SELECT statement imposes additional criteria for filtering results, including conditions based on the number of associated companies and the production year.

5. **Sorting and Paging**: The result set is ordered and limited to provide a subset of results for performance benchmarking.

Each of these components tests and showcases various SQL functionalities and behaviors, making the query rich and suitable for performance testing.
