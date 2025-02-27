WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        COUNT(CASE WHEN ci.role_id IS NOT NULL THEN 1 END) AS total_cast,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE 1 END) AS cast_with_order,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS cast_without_order
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
YearlyMovieStats AS (
    SELECT 
        production_year,
        COUNT(*) AS total_movies,
        AVG(total_cast) AS avg_cast_per_movie,
        MIN(total_cast) AS min_cast_per_movie,
        MAX(total_cast) AS max_cast_per_movie,
        SUM(CASE WHEN total_cast > 0 THEN 1 ELSE 0 END) AS movies_with_cast
    FROM 
        RecursiveMovieCTE
    GROUP BY 
        production_year
),
MovieLinks AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        lt.link AS link_type
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.keyword,
    r.total_cast,
    r.cast_with_order,
    (r.cast_with_order::float / NULLIF(r.total_cast, 0) * 100) AS order_percentage,
    yms.total_movies AS yearly_total_movies,
    yms.avg_cast_per_movie AS avg_cast_in_year,
    ml.linked_movie_id,
    ml.link_type
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    YearlyMovieStats yms ON r.production_year = yms.production_year
LEFT JOIN 
    MovieLinks ml ON r.movie_id = ml.movie_id
WHERE 
    (yms.total_movies > 10 OR r.total_cast > 5 OR r.keyword = 'Action')
    AND r.cast_without_order > 0
ORDER BY 
    r.production_year DESC, 
    r.title ASC
LIMIT 50;

### Explanation of Query Constructs:
1. **CTEs**: Three Common Table Expressions (`RecursiveMovieCTE`, `YearlyMovieStats`, and `MovieLinks`) to modularly build the results.
2. **JOINs**: Multiple outer joins to include keywords and cast information, ensuring all movie titles are captured, even when they lack certain linkages.
3. **Aggregations**: Counting total cast members and calculating order percentages with safeguard against division by zero using `NULLIF`.
4. **CASE Statements**: Utilized for complex conditional counting and to deal with the NULL values intelligently in the aggregate functions.
5. **Filtering**: Inclusion of movies with specific conditions based on cast size and keywords, showcasing the use of complicated predicates.
6. **Ordering and Limits**: Clear ordering to prioritize recent movies while limiting results for performance benchmarking.
7. **Bizarre Semantic Usage**: 
   - Handling for `CAST` operation implies a nuanced understanding of numeric conversion to avoid computations yielding NULLs.
   - Use of `COALESCE` to manage potential gaps in keyword data elegantly.
   
This query serves as a rich ground for performance analysis in terms of execution time and resource utilization while also showcasing various SQL capabilities.
