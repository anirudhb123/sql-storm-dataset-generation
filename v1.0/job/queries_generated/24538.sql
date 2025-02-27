WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT co.id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT co.id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
), 
HighProfileMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        CASE 
            WHEN rm.company_count > 5 THEN 'High Profile'
            ELSE 'Low Profile'
        END AS profile_type
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 10
), 
MovieSummary AS (
    SELECT 
        hp.title,
        hp.production_year,
        hp.profile_type,
        COALESCE(SUM(CASE WHEN t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%') THEN 1 ELSE 0 END), 0) AS feature_count,
        COALESCE(SUM(CASE WHEN t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'documentary%') THEN 1 ELSE 0 END), 0) AS documentary_count
    FROM 
        HighProfileMovies hp
    JOIN 
        aka_title t ON hp.title_id = t.id
    GROUP BY
        hp.title, hp.production_year, hp.profile_type
)
SELECT 
    ms.title,
    ms.production_year,
    ms.profile_type,
    ms.feature_count,
    ms.documentary_count,
    CASE 
        WHEN ms.feature_count > ms.documentary_count THEN 'More Features'
        WHEN ms.feature_count < ms.documentary_count THEN 'More Documentaries'
        ELSE 'Equal Count'
    END AS count_comparison,
    CONCAT(ms.title, ' (', ms.production_year, ') - ', ms.profile_type) AS movie_display 
FROM 
    MovieSummary ms
WHERE 
    ms.feature_count IS NOT NULL 
    AND ms.documentary_count IS NOT NULL
ORDER BY 
    ms.production_year DESC, 
    ms.feature_count DESC;

In this elaborate SQL query, we are achieving the following:

1. **Common Table Expressions (CTEs):** We build three CTEs; `RankedMovies` that ranks movies based on company counts per production year, `HighProfileMovies` that categorizes the movies into "High Profile" and "Low Profile" based on the number of associated companies, and finally `MovieSummary` that aggregates feature and documentary counts.

2. **Outer Joins:** We utilize a LEFT JOIN in `RankedMovies` to include movies without company associations.

3. **Window Functions:** The `ROW_NUMBER()` function assigns ranks to movies based on their company count grouped by production year.

4. **Correlated Subqueries:** In `MovieSummary`, we include correlated subqueries to sum the counts of feature and documentary types.

5. **Complicated Predicates:** The `CASE` statements establish logical distinctions between high and low profile movies and more documentaries vs. features.

6. **String Expressions:** We illustrate how to create a display string for each movie using concatenation.

7. **NULL Logic:** We handle potential null values with `COALESCE` to avoid null output in feature and documentary counts.

8. **Ordering:** The final selection sorts results by production year and feature counts, providing insights into trends over time.

This query is designed for a complex benchmarking scenario, showcasing various SQL capabilities while adhering to the provided schema.
