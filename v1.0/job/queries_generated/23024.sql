WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
),
actors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ci.movie_id,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        ci.role_id IS NOT NULL
),
company_info AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind SEPARATOR ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
final_data AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        a.name AS actor_name,
        ci.companies,
        ci.company_types,
        md.rank
    FROM 
        movie_details md
    LEFT JOIN 
        actors a ON md.title_id = a.movie_id
    LEFT JOIN 
        company_info ci ON md.title_id = ci.movie_id
)
SELECT 
    fd.title,
    fd.production_year,
    COALESCE(fd.actor_name, 'No Actors') AS actor_name,
    COALESCE(fd.companies, 'No Companies') AS companies,
    CASE 
        WHEN fd.rank IS NULL THEN 'Unranked'
        WHEN fd.rank = 1 THEN 'Top Ranked'
        ELSE 'Ranked ' || fd.rank 
    END AS rank_status
FROM 
    final_data fd
WHERE 
    fd.production_year > 2000
    OR fd.companies IS NOT NULL
ORDER BY 
    fd.production_year DESC,
    fd.title ASC;

### Explanation of the query:
1. **Common Table Expressions (CTEs)**:
   - `movie_details`: Gathers movie titles along with the production year and associated keywords, while utilizing the window function `ROW_NUMBER()` to create a rank based on the production year.
   - `actors`: Extracts actor names along with their associated movie IDs, ranking them alphabetically by actor names per movie using `RANK()`.
   - `company_info`: Aggregates company names and types for each movie into a comma-separated string.

2. **Outer Joins and NULL logic**: The main query uses left joins to bring together various pieces of information about the movies — actors and companies. COALESCE is used to substitute 'No Actors' and 'No Companies' when no data is present.

3. **Complex Predicates and Grouping**: The final selection filters for movies post-2000 or those that have associated companies. The use of GROUP_CONCAT allows for interesting string aggregation behavior.

4. **Bizarre SQL Semantics**: The behavior of `RANK()` and `ROW_NUMBER()` are leveraged, alongside string concatenation using `GROUP_CONCAT`, which might not be supported in some SQL variants, presenting a "bizarre" cross-database compatibility scenario.

5. **Final Output**: The query ends by selecting relevant fields and sorts the output first by production year and then by title. The results provide insights into movies, their associated actors, companies, and statuses with unique naming behavior and rank representations.
