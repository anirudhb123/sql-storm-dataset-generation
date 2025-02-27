WITH RECURSIVE top_movies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        SUM(ci.nr_order) AS total_cast 
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id 
    GROUP BY 
        t.id 
    ORDER BY 
        total_cast DESC 
    LIMIT 10
), 
movie_details AS (
    SELECT 
        t.movie_id, 
        t.title, 
        COALESCE(mk.keyword, 'No Keyword') AS keyword,
        ARRAY_AGG(DISTINCT c.name) AS companies,
        ROW_NUMBER() OVER (PARTITION BY t.movie_id ORDER BY c.name) AS company_rank,
        CASE 
            WHEN t.production_year IS NULL THEN 'Year Unknown'
            ELSE CAST(t.production_year AS TEXT)
        END AS production_year_str
    FROM 
        top_movies t 
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id 
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id 
    LEFT JOIN 
        company_name c ON mc.company_id = c.id 
    GROUP BY 
        t.movie_id, t.title, t.production_year
), 
actor_info AS (
    SELECT 
        p.name AS actor_name, 
        m.title AS movie_title, 
        m.production_year_str, 
        COUNT(DISTINCT ci.role_id) AS roles_played 
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id 
    JOIN 
        movie_details m ON ci.movie_id = m.movie_id 
    WHERE 
        p.name IS NOT NULL 
    GROUP BY 
        p.name, m.title, m.production_year_str 
), 
role_summary AS (
    SELECT 
        actor_name,
        movie_title,
        production_year_str,
        roles_played,
        RANK() OVER (PARTITION BY production_year_str ORDER BY roles_played DESC) AS role_rank 
    FROM 
        actor_info
)

SELECT 
    rs.actor_name,
    rs.movie_title,
    rs.production_year_str,
    rs.roles_played,
    CASE 
        WHEN rs.role_rank = 1 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS role_category,
    md.companies
FROM 
    role_summary rs
JOIN 
    movie_details md ON rs.movie_title = md.title
WHERE 
    rs.production_year_str <> 'Year Unknown'
    AND md.keyword NOT LIKE '%documentary%'
ORDER BY 
    rs.production_year_str, rs.roles_played DESC;

This SQL query performs several elaborate operations:

1. **CTE Usage**: Multiple Common Table Expressions (CTEs) are used to structure complex data retrieval. `top_movies` retrieves the top 10 movies based on the total number of cast members. `movie_details` gathers detailed information about those movies, handling potential NULLs with `COALESCE` and creating a string representation of the production year. `actor_info` collects information about actors and the number of roles they played in those movies.

2. **Window functions**: A `ROW_NUMBER` and `RANK` window functions are applied to neatly classify companies and actors based on the number of roles played.

3. **Outer Joins and Aggregations**: The query utilizes LEFT JOINs and aggregate functions like `SUM` and `ARRAY_AGG` to compile comprehensive data sets, ensuring even movies without associated companies or keywords are included.

4. **String Expressions and NULL Logic**: The use of `CASE` statements manages NULL production years and ranks actors.

5. **Complicated Queries with Conditions**: Finally, a complex `WHERE` clause filters out movies with 'Year Unknown' and excludes documentary genres, thus enriching the selective criteria under which data is presented.

This structure supports performance benchmarking due to its wide range of SQL constructs, challenging the database engine's optimization capabilities while retrieving a meaningful analysis of movies and their respective casts.
