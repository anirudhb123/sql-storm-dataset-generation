WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        kt.kind AS kind,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title m
    JOIN 
        aka_title at ON m.id = at.movie_id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        kind_type kt ON m.kind_id = kt.id
    GROUP BY 
        m.id, m.title, m.production_year, kt.kind
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieKeywords AS (
    SELECT 
        fm.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        FilteredMovies fm
    JOIN 
        movie_keyword mk ON fm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        fm.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.kind,
    mk.keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieKeywords mk ON fm.movie_id = mk.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.title;

This SQL query benchmarks string processing using the Join Order Benchmark schema. It identifies the top five movies by the number of cast members grouped by production year, retrieves additional keywords associated with those movies, and lists the results in descending order by production year and then title. The use of Common Table Expressions (CTEs) organizes the logic into distinct steps for clarity and efficiency while leveraging string aggregation for keyword representation.
