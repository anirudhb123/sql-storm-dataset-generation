WITH RECURSIVE movie_cast AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        1 AS depth
    FROM
        cast_info ci
    WHERE
        ci.role_id IS NOT NULL

    UNION ALL

    SELECT
        mc.movie_id,
        mc.person_id,
        depth + 1
    FROM
        movie_cast mc
    JOIN
        cast_info ci ON mc.movie_id = ci.movie_id
    WHERE
        ci.role_id IS NULL
),

aggregated_cast AS (
    SELECT
        mc.movie_id,
        COUNT(mc.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM
        movie_cast mc
    JOIN
        aka_name a ON mc.person_id = a.person_id
    GROUP BY
        mc.movie_id
),

movie_keywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)

SELECT
    t.title,
    t.production_year,
    ac.total_cast,
    ac.actor_names,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT c.id) OVER (PARTITION BY t.id) AS number_of_company_roles,
    COUNT(DISTINCT ci.id) AS role_count
FROM
    title t
LEFT JOIN
    aggregated_cast ac ON t.id = ac.movie_id
LEFT JOIN
    movie_keywords mk ON t.id = mk.movie_id
LEFT JOIN
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN
    company_name c ON mc.company_id = c.id
LEFT JOIN
    company_type ct ON mc.company_type_id = ct.id
WHERE
    t.production_year IS NOT NULL
    AND t.title IS NOT NULL
    AND (mk.keywords IS NULL OR mk.keywords != '')
ORDER BY
    t.production_year DESC,
    ac.total_cast DESC;

### Explanation

1. **Recursive CTE**: `movie_cast` builds a hierarchy of movie cast members, starting from those with a defined `role_id`. The recursion captures cases where there might be no role associated with a person.

2. **Aggregated CTE**: `aggregated_cast` computes the total number of cast members per movie and concatenates their names into a single string.

3. **Keyword Aggregation**: `movie_keywords` collects all keywords related to each movie, allowing multiple keywords to be listed in one column.

4. **Main Query**: The final query selects relevant movie information, joining the title with aggregated cast data, keywords, and company roles. LEFT JOIN is utilized to ensure all titles are included, even if they lack some data.

5. **Window Functions**: A COUNT window function calculates the number of unique companies tied to each movie.

6. **COALESCE**: This is used to provide a fallback string when no keywords are associated with a movie.

7. **Complex Conditions**: The WHERE clause filters out records with NULL values for `production_year` and `title`, while specifically requiring at least some keywords to be present.

8. **Final Sorting**: The results are ordered by production year (most recent first) and total cast size (largest first), providing a structured and meaningful output for analysis.
