WITH ranked_movies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
filtered_movies AS (
    SELECT 
        r.title,
        r.production_year,
        r.cast_count
    FROM 
        ranked_movies r
    WHERE 
        r.rank <= 5 -- Get top 5 movies per year
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_summary AS (
    SELECT 
        mt.id AS movie_id,
        COALESCE(mi.info, 'No Info') AS info_summary,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mi.info
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    mk.keywords,
    mis.info_summary,
    mis.company_count
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_keywords mk ON mk.movie_id = (
        SELECT movie_id 
        FROM movie_keyword 
        WHERE movie_keyword.movie_id = fm.movie_id 
        LIMIT 1
    )
LEFT JOIN 
    movie_info_summary mis ON mis.movie_id = (
        SELECT movie_id 
        FROM movie_info 
        WHERE movie_info.movie_id = fm.movie_id 
        LIMIT 1
    )
WHERE 
    (fm.production_year IS NOT NULL OR fm.production_year IS NULL)
ORDER BY 
    fm.production_year ASC, fm.cast_count DESC;

This query performs several interesting tasks:

1. **Common Table Expressions (CTEs)**: 
   - `ranked_movies` ranks movies based on the number of unique cast members per production year.
   - `filtered_movies` filters down to the top 5 ranked movies per year.
   - `movie_keywords` aggregates keywords associated with each movie.
   - `movie_info_summary` summarizes information for each movie, counting associated companies.

2. **Outer Joins**: Left joins are used to ensure all movies are included, even if they have no cast or related information, ensuring that no data is inadvertently excluded.

3. **Correlated Subqueries**: Used in the join conditions to avoid mistakenly returning multiple rows.

4. **String Aggregation**: The query aggregates keywords into a single string for each movie, showcasing the power of SQL string functions.

5. **Complicated Predicates**: The predicate `(fm.production_year IS NOT NULL OR fm.production_year IS NULL)` is a baffling redundancy but adheres to the bizarre SQL semantics.

6. **NULL Logic**: The `COALESCE` function ensures that if there's no information, a default value is returned, demonstrating handling NULL values.

7. **Sorting**: Final results are sorted by production year and cast count, allowing for intuitive reading of movie stats.

This comprehensive query elegantly highlights various SQL functionalities while also illustrating some obscure and rarely used SQL semantics.
