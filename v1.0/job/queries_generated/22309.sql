WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(cc.movie_id) OVER (PARTITION BY at.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title) AS rank_per_year,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY at.id) AS notes_count
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON ci.movie_id = at.movie_id
    WHERE
        at.production_year IS NOT NULL
        AND at.production_year BETWEEN 2000 AND 2020
),
GenresMovies AS (
    SELECT
        mt.movie_id,
        STRING_AGG(DISTINCT gt.kind, ', ') AS genres
    FROM
        movie_keyword mk
    JOIN
        keyword k ON k.id = mk.keyword_id
    JOIN
        kind_type gt ON gt.id = k.id -- Assuming kind_type is somehow related to keyword here; adjust logic as needed
    GROUP BY
        mt.movie_id
),
MovieCompanies AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT co.name) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name co ON co.id = mc.company_id
    GROUP BY
        mc.movie_id
)
SELECT 
    rm.title, 
    rm.production_year,
    rm.cast_count,
    rm.rank_per_year,
    rm.notes_count,
    gm.genres,
    COALESCE(cmp.company_count, 0) AS company_count,
    CASE 
        WHEN rm.cast_count > 10 AND rm.notes_count = 0 THEN 'High Cast, No Notes' 
        WHEN rm.notes_count > 5 THEN 'Many Notes'
        ELSE 'Standard'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    GenresMovies gm ON rm.movie_id = gm.movie_id
LEFT JOIN 
    MovieCompanies cmp ON rm.movie_id = cmp.movie_id
WHERE
    (CAST(rm.production_year AS TEXT) LIKE '20%' OR rm.cast_count < 5)
    AND rb.production_year IS NOT NULL
ORDER BY 
    rm.production_year, 
    rm.cast_count DESC, 
    rm.title;

### Explanation:
1. **CTEs**:
   - `RankedMovies`: This Common Table Expression (CTE) selects movies produced between 2000 and 2020, calculating the number of cast members (`cast_count`), ranking movies by year (`rank_per_year`), and counting non-null notes for each movie (`notes_count`).
   - `GenresMovies`: Retrieves genres associated with movies by aggregating keyword information into a string.
   - `MovieCompanies`: Count the number of distinct companies involved with each movie.

2. **Main Query**: 
   - Joins the CTEs to get a comprehensive view of the movies, including their cast count, genre, and number of associated companies.
   - Uses `COALESCE` to handle potential NULL values for `company_count`.

3. **Complex Conditions**: 
   - Includes a case statement to categorize movies based on cast count and note count.

4. **Filtering & Ordering**: 
   - The `WHERE` clause applies various filters related to production years and cast counts, and results are ordered by production year and cast count.

This query aims to benchmark complex SQL operations such as CTEs, JOINS, aggregation, window functions, and conditional logic.
