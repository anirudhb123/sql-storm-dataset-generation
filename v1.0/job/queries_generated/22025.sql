WITH classified_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        COALESCE(keyword_counts.keyword_count, 0) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            COUNT(*) AS keyword_count
        FROM 
            movie_keyword mk
        GROUP BY 
            mk.movie_id
    ) AS keyword_counts ON t.id = keyword_counts.movie_id
    WHERE 
        t.production_year IS NOT NULL
),

cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    GROUP BY 
        ci.movie_id
)

SELECT 
    ct.title_id,
    ct.title,
    ct.production_year,
    ct.keyword,
    ct.keyword_count,
    COALESCE(cd.total_cast, 0) AS total_cast,
    cd.cast_names,
    LEAST(ct.keyword_count, COALESCE(cd.total_cast, 0)) AS min_count,
    CASE 
        WHEN ct.production_year < (CURRENT_DATE - INTERVAL '10 years') THEN 'Classic'
        WHEN ct.production_year >= (CURRENT_DATE - INTERVAL '10 years') AND ct.production_year < CURRENT_DATE THEN 'Recent'
        ELSE 'Upcoming'
    END AS time_frame
FROM 
    classified_titles ct
LEFT JOIN 
    cast_details cd ON ct.title_id = cd.movie_id
WHERE 
    (ct.keyword_count > 3 OR cd.total_cast IS NULL)
    AND (cd.total_cast IS NULL OR cd.total_cast >= 5)
ORDER BY 
    ct.production_year ASC, ct.keyword_count DESC
LIMIT 50;


### Explanation:

1. **Common Table Expressions (CTEs):**
   - `classified_titles`: Gathers all titles along with their production year and associated keywords. It computes the number of keywords per movie.
   - `cast_details`: Counts distinct cast members per movie and concatenates their names into a string, utilizing `LISTAGG`.

2. **Main Query:**
   - Combines data from the CTEs, allowing for complex filtering and ordering.
   - Includes calculations like `LEAST()` to find the minimum value between `keyword_count` and `total_cast`.

3. **Filtering Criteria:**
   - Filters throw only movies with more than three keywords or no cast information at all.
   - Requires that either the total cast is null or has at least five members.

4. **Dynamic Classification and Order:**
   - Classifies each movie into 'Classic', 'Recent', or 'Upcoming' based on its production year relative to the current date.
   - Orders results by `production_year` and `keyword_count`.

5. **Potential NULL Logic:**
   - Utilizes `COALESCE` to handle null values in cast counts, ensuring counts default to zero if no data is available.

This query is constructed to explore various SQL features and serves as a benchmark for performance, complexity, and understanding of SQL execution strategies like joins, aggregations, and filtering.
