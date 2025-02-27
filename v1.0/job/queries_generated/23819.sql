WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RAND()) AS random_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS movie_count
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
),

TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        random_rank
    FROM 
        RankedMovies
    WHERE 
        random_rank <= 10
),

JoinedCast AS (
    SELECT 
        m.movie_id,
        ak.name AS actor_name,
        p.gender,
        c.nr_order,
        ct.kind AS role 
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        title m ON m.id = c.movie_id
    LEFT JOIN 
        role_type rt ON rt.id = c.role_id
    LEFT JOIN 
        comp_cast_type ct ON ct.id = c.person_role_id
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    GROUP_CONCAT(DISTINCT jc.actor_name ORDER BY jc.nr_order SEPARATOR ', ') AS actors,
    SUM(CASE WHEN jc.gender = 'F' THEN 1 ELSE 0 END) AS female_actors,
    SUM(CASE WHEN jc.gender = 'M' THEN 1 ELSE 0 END) AS male_actors,
    CASE WHEN COUNT(DISTINCT jc.actor_name) = 0 THEN 'No Cast' ELSE 'Cast Available' END AS cast_presence
FROM 
    TopRankedMovies tm
LEFT JOIN 
    JoinedCast jc ON tm.movie_id = jc.movie_id
GROUP BY 
    tm.movie_id,
    tm.title,
    tm.production_year
HAVING 
    CAST(NULLIF(SUM(CASE WHEN jc.gender IS NULL THEN 1 END), 0) AS boolean) = TRUE 
    OR female_actors >= 1
ORDER BY 
    tm.production_year DESC, 
    tm.title;

### Explanation of the Query:
1. **CTEs (Common Table Expressions)**:
   - `RankedMovies`: Selects movies and assigns a random rank within each production year, filtering by feature films and ensuring `production_year` is not null.
   - `TopRankedMovies`: Limits the number of random movies selected from each production year to 10.
   - `JoinedCast`: Joins various tables to assemble a list of actors for each movie along with their roles and genders.

2. **Aggregation**:
   - Grouping by movie details allows counting actors by gender and generating a list of actor names.

3. **CASE Statements**:
   - Used to count male and female actors specially, as well as to provide a message based on the cast presence.

4. **HAVING Clause**:
   - The use of `NULLIF` and boolean syntax ensures that the presence of certain conditions is enforced, including checking for null cast members.

5. **String Aggregation**:
   - `GROUP_CONCAT` serves to collect actor names into a single string for easier readability.

6. **Randomization & Filtering**:
   - The random rank allows the test of performance under fluctuating conditions, effectively simulating different data loads across runs. 

This query showcases complexity by combining multiple SQL features, while also leveraging various SQL semantics for comprehensive benchmarking.
