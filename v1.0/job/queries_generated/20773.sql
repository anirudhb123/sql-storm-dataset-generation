WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank,
        COUNT(DISTINCT kv.keyword) OVER (PARTITION BY a.id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kv ON mk.keyword_id = kv.id
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
)

SELECT 
    r.title,
    r.production_year,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    COALESCE(n.name, 'Unnamed Actor') AS actor_name,
    r.keyword_count
FROM 
    RankedMovies r
LEFT JOIN 
    movie_companies mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id AND cn.country_code IS NOT NULL
LEFT JOIN 
    complete_cast cc ON r.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id AND ci.nr_order = 1
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
WHERE 
    r.year_rank <= 3
    AND n.name IS NOT NULL
    AND r.keyword_count > 1
ORDER BY 
    r.production_year DESC,
    r.keyword_count DESC
LIMIT 100
UNION ALL
SELECT 
    'Total Keywords' AS title,
    NULL AS production_year,
    NULL AS company_name,
    NULL AS actor_name,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count
FROM 
    movie_keyword mk
WHERE 
    mk.keyword_id IS NOT NULL;

### Explanation:

1. **Common Table Expression (CTE)**: `RankedMovies` creates a temporary result set to rank movies by production year. It includes a count of distinct keywords related to each movie.

2. **LEFT JOINs**: The query retrieves related data such as company names and actor names while allowing for the possibility of NULLs in company names and ensuring default values if no data is found.

3. **Correlated Subquery**: The subquery in the `WHERE` clause filters movies based on their kind, which adds complexity.

4. **COALESCE**: Used to provide default values for columns where NULLs may exist.

5. **UNION ALL**: Combines the results of the main query with a separate aggregate query that counts all distinct keywords across all movies.

6. **Complicated predicates**: Filtering by ranks, keyword counts, not-null conditions, and several layers of joins ensure only the most relevant and quality data are selected.

7. **Order By & Limit**: The output is ordered by production year and keyword count, limited to 100 records to showcase the most significant results.

This SQL is designed for performance benchmarking by demonstrating various aspects of SQL functionality, utilizing multiple constructs and handling NULL logic effectively while also addressing corner cases.
