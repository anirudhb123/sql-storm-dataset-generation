WITH RECURSIVE movie_roles AS (
    SELECT
        ci.movie_id,
        ci.person_id,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
),
ranked_titles AS (
    SELECT
        at.id AS title_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT cr.person_id) DESC) AS title_rank
    FROM
        aka_title at
    LEFT JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN
        movie_roles cr ON ci.movie_id = cr.movie_id
    GROUP BY
        at.id, at.title, at.production_year
),
company_movie_counts AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    GROUP BY
        mc.movie_id
)
SELECT
    at.title AS movie_title,
    at.production_year,
    r.role AS role,
    ci.nr_order,
    COALESCE(cmc.company_count, 0) AS company_count,
    rt.role_order
FROM
    aka_title at
JOIN
    movie_roles r ON at.movie_id = r.movie_id
JOIN
    cast_info ci ON r.movie_id = ci.movie_id AND r.person_id = ci.person_id
LEFT JOIN
    company_movie_counts cmc ON at.id = cmc.movie_id
WHERE
    at.production_year >= 2000
    AND (r.role IS NOT NULL OR ci.note IS NULL)
ORDER BY
    at.production_year DESC,
    company_count DESC,
    r.role_order;

### Explanation:
1. **Recursive CTE (`movie_roles`)**: This constructs a list of all roles for every person in the `cast_info` table, along with a row number for each person's role per movie.
2. **Ranked Titles CTE (`ranked_titles`)**: This ranks titles per production year based on the count of distinct persons associated with each movie.
3. **Company Movie Counts CTE (`company_movie_counts`)**: This counts the unique companies associated with each movie from the `movie_companies` table.
4. **Main Query**: It selects movies from the `aka_title` table, joins with roles, cast info, and company counts while applying conditions on production years and role/null logic. The final results are ordered by the production year and company count. 

This query could be useful for performance benchmarking and understanding the intricacies of joins, subqueries, window functions, and more in SQL.

