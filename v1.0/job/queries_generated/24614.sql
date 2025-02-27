WITH movie_with_cast AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        STRING_AGG(CONCAT_WS(' - ', ak.name, rc.role) ORDER BY rc.nr_order) AS cast_names,
        COUNT(DISTINCT rc.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info rc ON mt.id = rc.movie_id
    LEFT JOIN 
        aka_name ak ON rc.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
        AND ak.name IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
best_movies AS (
    SELECT 
        mwc.movie_title,
        mwc.production_year,
        mwc.cast_count,
        ROW_NUMBER() OVER (PARTITION BY mwc.production_year ORDER BY mwc.cast_count DESC) AS rank
    FROM 
        movie_with_cast mwc
    WHERE 
        mwc.cast_count > 0
),
unique_keywords AS (
    SELECT 
        mw.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        aka_title mw
    LEFT JOIN 
        movie_keyword mk ON mw.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mw.id
)
SELECT 
    bm.movie_title,
    bm.production_year,
    bm.cast_count,
    uk.keywords,
    CASE 
        WHEN bm.rank = 1 THEN 'Top Movie'
        WHEN bm.rank <= 5 THEN 'Top 5 Movie'
        ELSE 'Below Top 5'
    END AS ranking_label,
    COALESCE(NULLIF(uk.keywords, ''), 'No Keywords') AS keyword_info
FROM 
    best_movies bm
LEFT JOIN 
    unique_keywords uk ON bm.movie_title = uk.movie_id
WHERE 
    bm.rank <= 5
ORDER BY 
    bm.production_year DESC, bm.cast_count DESC;

### Explanation:

1. **CTEs (`WITH` clause)**: 
   - `movie_with_cast`: Aggregates movie titles and their cast information for movies produced from 2000 onward. It counts distinct cast members and concatenates their names in a string.
   - `best_movies`: Ranks the movies based on the number of cast members for each production year.
   - `unique_keywords`: Gathers unique keywords for the movies to enrich the final output.

2. **Main Query**: 
   - Joins the best movies with their corresponding keywords.
   - Applies a `CASE` expression to classify movies into tiers based on their rank.
   - Uses `COALESCE` and `NULLIF` to handle possible NULL or empty keyword cases, ensuring clarity in the output.

3. **Outer Joins**: Used in CTEs and the main query to ensure that all movies are considered, regardless of whether they have cast information or keywords.

4. **Complex Predicate**: The filters ensure robust data selection, allowing for the exclusion of unwanted movie titles or NULL values.

5. **Window Function**: The `ROW_NUMBER()` function assigns ranks to the best movies based on their cast size, partitioned by the production year.

6. **String Functions**: The `STRING_AGG` and `CONCAT_WS` functions manage string concatenation and ordering for names and keywords. 

This query could serve as a benchmark to test the performance of complex SQL constructs and handle large data volumes in the `Join Order Benchmark` schema.
