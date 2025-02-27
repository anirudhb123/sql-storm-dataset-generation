WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(NULLIF(cast.nr_order, 0), 1) AS cast_order,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COALESCE(NULLIF(cast.nr_order, 0), 1)) AS rn,
        (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = t.id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info cast ON t.id = cast.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_order,
        rn,
        total_cast
    FROM 
        MovieCTE
    WHERE 
        production_year >= 2000 
        AND production_year < 2025
        AND rn <= 3
),
CastDetails AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.cast_order,
        f.total_cast,
        ak.name AS actor_name,
        rt.role AS role_name
    FROM 
        FilteredMovies f
    LEFT JOIN 
        cast_info ci ON f.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieKeywords AS (
    SELECT 
        f.movie_id,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        FilteredMovies f
    LEFT JOIN 
        movie_keyword mk ON f.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        f.movie_id
)
SELECT 
    cd.movie_id,
    cd.title,
    cd.production_year,
    cd.cast_order,
    cd.actor_name,
    cd.role_name,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    CastDetails cd
FULL OUTER JOIN 
    MovieKeywords mk ON cd.movie_id = mk.movie_id
WHERE 
    cd.cast_order IS NOT NULL 
    OR mk.keywords IS NOT NULL
ORDER BY 
    cd.production_year DESC,
    cd.cast_order ASC NULLS LAST;

This SQL query does the following:

1. **Common Table Expressions (CTEs)**:
   - `MovieCTE`: Selects movies with their title, production year, and cast order. It computes a row number and counts total cast members, handling possible NULLs using `COALESCE` and `NULLIF`.
   - `FilteredMovies`: Filters movies from the year 2000 to 2025 and limits cast members to the top 3 by order.
   - `CastDetails`: Joins filtered movies with actor names and roles.
   - `MovieKeywords`: Aggregates keywords related to movies.

2. **Outer Join**: Uses a `FULL OUTER JOIN` to include movies with or without cast details or keywords.

3. **Dynamic and Bizarre Logic**: Employs `COALESCE`, `NULLIF`, and corner cases in filtering by considering roles and cast orders.

4. **String Handling**: Uses `GROUP_CONCAT` to aggregate keywords for each movie, applying a condition to return 'No Keywords' if there are none.

5. **Sorting**: Orders the results by production year and cast order, handling NULLs explicitly.

This query can be used to benchmark performance considering various SQL constructs and complexity of operations.
