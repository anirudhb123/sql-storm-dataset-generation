WITH ranked_movies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_per_year
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id,
        t.title,
        t.production_year
),
top_movies AS (
    SELECT
        rm.*
    FROM
        ranked_movies rm
    WHERE
        rm.rank_per_year <= 3
),
key_movie_info AS (
    SELECT
        t.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT ci.note, '; ') AS cast_notes
    FROM
        top_movies t
    LEFT JOIN
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_info mi ON t.movie_id = mi.movie_id
    LEFT JOIN
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY
        t.movie_id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(k.keywords, 'No Keywords') AS keywords,
    COALESCE(k.cast_notes, 'No Cast Notes') AS cast_notes,
    COALESCE(m.company_name, 'Unknown Company') AS company_name
FROM
    top_movies tm
LEFT JOIN
    (SELECT
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_name
     FROM
        movie_companies mc
     LEFT JOIN
        company_name cn ON mc.company_id = cn.id
     WHERE
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')
     GROUP BY
        mc.movie_id) m ON tm.movie_id = m.movie_id
LEFT JOIN
    key_movie_info k ON tm.movie_id = k.movie_id
ORDER BY
    tm.production_year DESC,
    CAST(tm.cast_count AS INTEGER) DESC NULLS LAST;
This query accomplishes the following:

1. **CTEs for Organization**: It uses Common Table Expressions (CTEs) to break down the logic into manageable parts:
   - `ranked_movies` identifies movies and counts their casts, ranking them by year.
   - `top_movies` filters the top-ranked movies for the top 3 in terms of cast size per year.
   - `key_movie_info` aggregates the keywords and any notes from the cast for those top movies.

2. **Complex Joins and Filters**: It makes use of multiple outer joins to combine data from various subsidiary tables related to movies, keywords, cast information, and production companies.

3. **String Aggregation**: The query aggregates keywords and cast notes as strings, combining multiple values into a single, well-formatted output.

4. **NULL Logic**: By using `COALESCE`, it gracefully handles situations where there are no keywords or company names, providing default text if they do not exist.

5. **Order with NULL Handling**: The final selection orders the results first by production year (descending) and then by cast count, carefully placing NULL counts at the end of the results. 

This SQL query is designed to showcase the capabilities of the SQL language while drawing from a rich dataset structure.
