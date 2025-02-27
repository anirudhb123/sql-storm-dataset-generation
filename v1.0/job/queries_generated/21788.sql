WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS title,
        mt.production_year AS year,
        mk.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mk.keyword) AS keyword_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
), CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
), OverlappingDetails AS (
    SELECT 
        DISTINCT mv.movie_id,
        mv.title,
        COALESCE(cd.cast_count, 0) AS total_cast,
        md.keyword,
        md.year,
        md.keyword_rank
    FROM 
        MovieDetails md
    FULL JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
    WHERE 
        md.keyword IS NOT NULL
)
SELECT 
    od.movie_id,
    od.title,
    od.total_cast,
    od.keyword,
    od.year,
    (od.total_cast * CASE 
        WHEN od.year < 2000 THEN 1
        WHEN od.year BETWEEN 2000 AND 2010 THEN 1.5
        ELSE 2 
    END) AS weighted_cast,
    CASE 
        WHEN od.keyword IS NULL THEN 'No Keywords'
        ELSE 'Has Keywords' 
    END AS keyword_status,
    CASE 
        WHEN od.keyword_rank = 1 THEN 'Top Keyword'
        WHEN od.keyword_rank IS NULL THEN 'Undefined Rank'
        ELSE 'Other Rank' 
    END AS keyword_rank_status
FROM 
    OverlappingDetails od
WHERE 
    od.total_cast >= 1
ORDER BY 
    weighted_cast DESC, year ASC
LIMIT 10;

### Explanation:

1. **Common Table Expressions (CTEs)**:
   - `MovieDetails`: Retrieves movies that are dramas and their associated keywords while filtering to only include valid production years. It ranks keywords for each movie.
   - `CastDetails`: Aggregates the cast information for each movie to get the total number of distinct actors and concatenate their names.
   - `OverlappingDetails`: Combines the results from both CTEs, attempting to match movies with their keyword and cast counts, using a full outer join to include all relevant records.

2. **Final Select Statement**:
   - Selects from `OverlappingDetails`, calculates a weighted cast count based on production year, checks the status of keywords, and ranks keywords according to the rank obtained in the `MovieDetails` CTE.

3. **Complicated Expressions**:
   - Uses the `CASE` statements to derive meaningful insights about the movies based on year brackets and keyword presence.

4. **String Aggregation**:
   - `STRING_AGG` is used to create a comma-separated list of actors in the cast.

5. **NULL Logic**:
   - Utilizes `COALESCE` to handle NULLs effectively, considering movies with no cast.

6. **Ordering and Limiting**:
   - Orders results based on calculated weighted cast and production year, limiting the results to the top 10 for performance benchmarking. 

This query showcases SQL's ability to handle complex data extraction and manipulation tasks while illustrating the use of various advanced features.
