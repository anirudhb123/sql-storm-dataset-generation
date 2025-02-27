WITH ranked_movies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        DENSE_RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_per_year
    FROM title t
    LEFT JOIN cast_info c ON c.movie_id = t.id
    GROUP BY t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM ranked_movies rm
    WHERE rm.rank_per_year = 1
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
company_titles AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(ct.companies, 'No Companies') AS companies
FROM filtered_movies fm
LEFT JOIN movie_keywords mk ON fm.title_id = mk.movie_id
LEFT JOIN company_titles ct ON fm.title_id = ct.movie_id
WHERE fm.production_year > 2000
    AND (SELECT COUNT(*) FROM aka_title at WHERE at.title = fm.title AND at.production_year = fm.production_year) > 1
ORDER BY fm.production_year DESC, fm.cast_count DESC;

This SQL query achieves the following:

1. **Common Table Expressions (CTEs)**: It uses four CTEs to handle the data in step-wise fashion:
   - `ranked_movies`: Computes the count of cast members and ranks movies by their year.
   - `filtered_movies`: Selects only the top-ranked movies for each production year.
   - `movie_keywords`: Aggregates keywords associated with each movie.
   - `company_titles`: Aggregates production companies for each movie.

2. **LEFT JOINs**: The main query combines data from the filtered movies with the movie keywords and company names using `LEFT JOINs`. This allows for the inclusion of movies without keywords or companies.

3. **String Aggregation**: It uses `STRING_AGG` to concatenate related keywords and company names into a single string, ensuring a more readable format.

4. **Correlated Subquery**: The `WHERE` clause includes a correlated subquery to filter movies that have more than one entry in the `aka_title` table, ensuring that only titles with multiple known aliases are included.

5. **COALESCE Function**: It ensures that if there are no keywords or companies, the output returns default text ("No Keywords" or "No Companies") instead of NULL.

6. **Ordering and Filtering**: The final results are ordered by production year (descending) and the number of cast members (descending). It also applies a filter for movies produced after the year 2000.

This elaborate query prioritizes performance considerations while demonstrating complex SQL constructions.
