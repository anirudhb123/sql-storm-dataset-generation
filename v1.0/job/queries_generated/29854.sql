WITH ranked_titles AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON a.id = c.movie_id
    GROUP BY a.id, a.title, a.production_year
),
filtered_titles AS (
    SELECT 
        *,
        CASE 
            WHEN total_cast > 10 THEN 'Featured'
            WHEN total_cast BETWEEN 5 AND 10 THEN 'Moderate'
            ELSE 'Minor'
        END AS cast_size_category
    FROM ranked_titles
)
SELECT 
    tt.title,
    tt.production_year,
    tt.total_cast,
    tt.keywords,
    tt.cast_size_category
FROM filtered_titles tt
WHERE tt.rank <= 5
ORDER BY tt.production_year DESC, tt.total_cast DESC;

This query accomplishes the following tasks:

1. **Creates a Common Table Expression (CTE)** named `ranked_titles` that aggregates data from the `aka_title`, `movie_keyword`, `keyword`, and `cast_info` tables. It counts the total number of distinct cast members per title while collecting their associated keywords as a comma-separated list.

2. **Assigns rank** to each title based on the number of cast members, grouped by production year.

3. **Filters the results** in another CTE named `filtered_titles`, which categorizes titles into 'Featured', 'Moderate', and 'Minor' based on the size of the cast.

4. **Selects and orders** the top five titles per production year by total cast size, only including those from the `filtered_titles` CTE, and sorts them by production year descending and then by total cast descending. 

This combination provides insights into movie titles that are notable for their large casts and the keywords associated with them while ranking them within their respective production years.
