WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(c.kind, 'UNKNOWN') AS company_kind,
        ARRAY[COALESCE(k.keyword, 'NO_KEYWORD')] AS keywords,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COALESCE(m.production_year, 0) DESC) AS rn
    FROM
        aka_title m
        LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
        LEFT JOIN keyword k ON k.id = mk.keyword_id
        LEFT JOIN movie_companies mc ON mc.movie_id = m.id
        LEFT JOIN company_type c ON c.id = mc.company_type_id
    WHERE
        m.production_year IS NOT NULL
        AND m.production_year > 2000
    
    UNION ALL

    SELECT
        mh.movie_id,
        mh.title,
        mh.company_kind,
        mh.keywords || ARRAY[COALESCE(k2.keyword, 'NO_KEYWORD')] AS keywords,
        mh.rn
    FROM
        MovieHierarchy mh
        LEFT JOIN movie_link ml ON ml.movie_id = mh.movie_id
        LEFT JOIN aka_title m2 ON m2.id = ml.linked_movie_id
        LEFT JOIN movie_keyword mk2 ON mk2.movie_id = m2.id
        LEFT JOIN keyword k2 ON k2.id = mk2.keyword_id
    WHERE
        mh.rn < 3
),
FilteredMovies AS (
    SELECT
        m.movie_id,
        m.title,
        m.company_kind,
        UNNEST(m.keywords) AS keyword
    FROM
        MovieHierarchy m
)
SELECT
    f.movie_id,
    f.title,
    COUNT(DISTINCT f.keyword) AS unique_keyword_count,
    STRING_AGG(DISTINCT f.keyword, ', ') AS all_keywords,
    CASE 
        WHEN COUNT(DISTINCT f.keyword) > 3 THEN 'Popular'
        WHEN COUNT(DISTINCT f.keyword) IS NULL OR COUNT(DISTINCT f.keyword) = 0 THEN 'No Keywords'
        ELSE 'General'
    END AS keyword_category
FROM
    FilteredMovies f
GROUP BY
    f.movie_id, f.title
HAVING
    COUNT(DISTINCT f.keyword) > 1 OR f.title IS NOT NULL
ORDER BY
    unique_keyword_count DESC, f.title;

### Explanation:
1. **CTE (Common Table Expression)** - `MovieHierarchy`: The first CTE fetches a list of movies produced after 2000, along with associated keywords. It uses a recursive structure to build relationships between linked movies, capturing a hierarchical relationship of movie links. Window functions (ROW_NUMBER) help in the identification of relevant records.

2. **Array and COALESCE** - An array is constructed to hold keywords, ensuring that if there are no keywords, a placeholder of "NO_KEYWORD" is added by default using `COALESCE`.

3. **UNNEST Function** - The second CTE (`FilteredMovies`) unpacks the keywords from the array into rows for easier aggregation in subsequent operations.

4. **Aggregation** - In the final selection, we count unique keywords (with a check for nulls), concatenate them into a single string, and categorize movies based on the count of their unique keywords:
   - If greater than 3, it's marked as "Popular".
   - If there are no keywords, it is marked "No Keywords".
   - Otherwise, it's categorized as "General".

5. **HAVING Clause** - Filters the final result to ensure that only movies with more than one keyword or non-null titles are returned.

6. **Order By** - Results are organized first by the number of unique keywords (in descending order) and then alphabetically by title. 

This query explores various SQL features, complexities, and semantics while yielding an insightful result set on the movies after the year 2000 with their associated keywords and categorizations.
