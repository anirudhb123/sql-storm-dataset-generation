WITH RecursiveNames AS (
    SELECT
        a.id AS aka_id,
        a.person_id,
        COALESCE(NULLIF(a.name, ''), 'Unknown') AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY a.id, a.person_id, a.name
),
TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        SUM(CASE WHEN m.note IS NULL THEN 1 ELSE 0 END) AS null_notes
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    GROUP BY t.id, t.title, t.production_year
),
RankedActors AS (
    SELECT 
        rn.actor_name,
        rn.movie_count,
        RANK() OVER (ORDER BY rn.movie_count DESC) AS rank
    FROM 
        RecursiveNames rn
    WHERE 
        rn.movie_count > 0
)
SELECT 
    r.actor_name,
    t.title,
    t.production_year,
    IFNULL(t.keyword_count, 0) AS keyword_count,
    t.null_notes,
    RANK() OVER (PARTITION BY t.production_year ORDER BY t.keyword_count DESC) AS year_rank
FROM 
    RankedActors r
JOIN 
    title t ON r.movie_count > 5
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
WHERE 
    (t.production_year >= 2000 AND t.production_year <= 2022)
    AND t.title NOT LIKE '%Untitled%'
    AND (EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = t.id AND mi.info_type_id = 
        (SELECT id FROM info_type WHERE info ILIKE '%box office%'))
        OR t.production_year IS NULL)
ORDER BY 
    r.rank, t.production_year, t.keyword_count DESC;

### Explanation of Constructs Used
1. **CTEs (Common Table Expressions)**:
   - `RecursiveNames`: Computes the count of movies per actor and ensures names are not empty.
   - `TitleInfo`: Joins movie titles with keywords and counts them while also handling NULL notes.
   - `RankedActors`: Calculates a rank for actors based on their movie count using a window function.

2. **Joins**:
   - Used `LEFT JOIN` to ensure we still get every title even if it has no corresponding keywords or notes.

3. **Window Functions**:
   - `RANK()`: Used for both actor ranking by movie count and year ranking for titles based on keyword counts.

4. **NULL Logic**:
   - `IFNULL` and `NULLIF` functions to handle possible NULL cases for movie keywords and other fields.

5. **Complicated Predicates/Expressions**:
   - `EXISTS` clause includes a correlated subquery to check for the presence of specific info types, adding complexity.

6. **String Expressions**:
   - Use of `ILIKE` for case-insensitive searching and `NOT LIKE` to exclude certain titles.

7. **Set Operators**: 
   - Not utilized directly, but prevalent through the use of joins and the aggregation functions.

8. **Bizarre SQL Semantics**: 
   - Handling of names that could be empty or consist only of null values, showing the intricacies of real data.

This complex query balances multiple facets of SQL, ensuring robustness for performance benchmarking in a real-world and potential edge-case scenario.
