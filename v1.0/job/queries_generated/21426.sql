WITH movie_details AS (
    SELECT 
        at.title,
        at.production_year,
        ak.name AS actor_name,
        pc.kind AS production_company_type,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_order
    FROM
        aka_title at
    INNER JOIN
        cast_info ci ON at.movie_id = ci.movie_id
    INNER JOIN
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        movie_companies mc ON mc.movie_id = at.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        company_type pc ON mc.company_type_id = pc.id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id = at.movie_id
    GROUP BY
        at.id, at.title, at.production_year, ak.name, pc.kind
)
SELECT
    md.title,
    md.production_year,
    md.actor_name,
    md.production_company_type,
    md.null_notes_count,
    md.keyword_count,
    CASE 
        WHEN md.actor_order = 1 AND md.null_notes_count > 0 THEN CONCAT('Starring: ', md.actor_name, ' - Note Count: ', md.null_notes_count)
        ELSE md.actor_name 
    END AS actor_info,
    COALESCE(
        (SELECT MAX(k.keyword) 
         FROM movie_keyword mk
         JOIN keyword k ON mk.keyword_id = k.id
         WHERE mk.movie_id = md.id),
         'No keywords'
    ) AS max_keyword
FROM
    movie_details md
WHERE
    md.production_year IS NOT NULL
    AND EXISTS (SELECT 1 FROM cast_info ci WHERE ci.movie_id = md.id AND ci.role_id IS NOT NULL)
ORDER BY 
    md.production_year DESC,
    md.keyword_count DESC,
    md.actor_name;

### Breakdown of Query Components:
- **Common Table Expression (CTE)**: `movie_details` collects relevant data across several tables, including aggregated null counts in notes and distinct keyword counts for each movie.
- **Joins**: It utilizes multiple `INNER JOIN` and `LEFT JOIN` constructs to bring together cast, company details, and keywords related to movies.
- **Aggregations**: Uses `SUM` to count null notes, and `COUNT(DISTINCT ...)` for keyword uniqueness.
- **Window Functions**: `ROW_NUMBER()` to order actors within the same movie.
- **Conditional Logic and String Manipulation**: Uses `CASE` when defining `actor_info`, and `CONCAT` to combine strings.
- **Subqueries**: A correlated subquery to derive the maximum keyword associated with each movie, with a fallback using `COALESCE`.
- **NULL Logic**: It checks for null production years and roles in a semi-outer logical condition.
- **Ordering**: Results are ordered by production year, keyword count, and actor names, reflecting a structured output for performance benchmarking.
