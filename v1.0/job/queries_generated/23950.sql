WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        c.country_code,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),
ActorCharacter AS (
    SELECT
        c.id AS cast_id,
        a.name AS actor_name,
        r.role AS actor_role,
        t.title AS movie_title,
        t.production_year
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        title t ON c.movie_id = t.id
    JOIN
        role_type r ON c.role_id = r.id
),
FilteredMovies AS (
    SELECT 
        mt.movie_id,
        COUNT(k.keyword) AS num_keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
    HAVING 
        COUNT(k.keyword) > 3
)
SELECT
    a.actor_name,
    a.movie_title,
    a.production_year,
    c.company_name,
    c.country_code,
    c.company_type,
    r.title_rank,
    f.num_keywords
FROM
    ActorCharacter a
LEFT JOIN
    CompanyMovies c ON a.movie_title = c.movie_id
LEFT JOIN
    RankedTitles r ON a.movie_title = r.title_id
LEFT JOIN
    FilteredMovies f ON a.movie_title = f.movie_id
WHERE
    a.actor_role IS NOT NULL
    AND a.actor_name IS NOT NULL
    AND ((c.country_code IS NULL OR c.country_code != 'USA') OR (c.company_type = 'Distributor'))
ORDER BY
    a.actor_name ASC,
    a.production_year DESC,
    r.title_rank
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;

### Explanation of the Query Components:

1. **Common Table Expressions (CTEs)**:
   - `RankedTitles`: Assigns a rank to titles based on their production year and ID, filtering out `NULL` years.
   - `CompanyMovies`: Joins movies with their respective companies and types.
   - `ActorCharacter`: Combines casts with their respective role and movie details.
   - `FilteredMovies`: Counts keywords associated with movies, filtering to include only those with more than three keywords.

2. **Joins**: 
   - Utilizes `LEFT JOIN` to ensure that all actor entries are retained even if there are no matching records in the company or ranking tables.

3. **Complex Predicates**:
   - The `WHERE` clause filters out actors and movies based on roles and presence of country codes, considering obscure conditions such as the distinction between `NULL` values for countries and specific company types.

4. **Window Functions**:
   - `ROW_NUMBER()` is used to rank the titles within their production years.

5. **String Expressions**: 
   - Uses string comparisons for country codes and company types while applying filters for actors.

6. **Null Logic**:
   - Conditions handle `NULL` country codes in various ways, showcasing SQL's capability to accommodate complex conditions.
  
7. **Ordering and Pagination**:
   - Results are ordered by actor name and production year, with pagination to fetch a specific subset of results.

This SQL query thus provides a robust benchmark for performance testing across a moderately complex schema with intricate joins and logical conditions.
