WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(c.person_id) AS num_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS year_rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY
        t.id, t.title, t.production_year
),
TopRankedMovies AS (
    SELECT
        title,
        production_year,
        num_cast
    FROM
        RankedMovies
    WHERE
        year_rank <= 5
),
MovieKeywords AS (
    SELECT
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM
        movie_keyword mt
    JOIN
        keyword k ON mt.keyword_id = k.id
    GROUP BY
        mt.movie_id
),
MoviesWithKeywords AS (
    SELECT
        trm.title,
        trm.production_year,
        trm.num_cast,
        mk.keyword_list
    FROM
        TopRankedMovies trm
    LEFT JOIN
        MovieKeywords mk ON trm.id = mk.movie_id
)
SELECT
    mwk.title,
    mwk.production_year,
    mwk.num_cast,
    COALESCE(mwk.keyword_list, 'No keywords') AS keyword_list,
    (SELECT COUNT(DISTINCT person_id)
     FROM cast_info ci
     WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = mwk.title LIMIT 1)
     AND ci.note IS NULL) AS no_note_cast_count
FROM
    MoviesWithKeywords mwk
WHERE
    mwk.num_cast > 1
ORDER BY
    mwk.production_year DESC, mwk.num_cast DESC;

### Explanation
1. **CTEs**: Multiple Common Table Expressions (CTEs) help in structuring the query neatly. They first rank the movies by the number of cast members by year, select the top-ranked movies, and gather related keywords.

2. **OUTER JOIN**: `LEFT JOIN` is used to join the movies with their corresponding keywords to include movies without keywords.

3. **STRING_AGG**: The aggregation function `STRING_AGG` is used to concatenate keywords for individual movies, which can be more effective for readability in results.

4. **COALESCE**: This is utilized to handle NULL values for movies without any keywords, replacing them with 'No keywords'.

5. **Correlated Subquery**: A subquery is provided to count distinct people in `cast_info` who have no notes associated with their roles, demonstrating the complexity and SQL subquery capabilities.

6. **Complicated Predicates/Expressions**: Various predicates are employed, ensuring only movies with more than one cast member are shown.

7. **Bizarre Semantics**: Includes aspects such as coalescing NULL values to a specific string and counting distinct entities based on complex relationships, showcasing the intricate nature of SQL joins and filtering.
