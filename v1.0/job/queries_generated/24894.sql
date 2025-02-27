WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id AS actor_id, 
        c.movie_id, 
        c.nr_order,
        COALESCE(a.name, 'Unknown Actor') AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
), 
title_info AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        k.keyword AS keywords,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        t.production_year IS NOT NULL 
        AND (t.production_year BETWEEN 2000 AND 2023)
    GROUP BY 
        t.id, t.title, t.production_year
), 
actor_activity AS (
    SELECT 
        ah.actor_id,
        ah.actor_name,
        COUNT(DISTINCT ah.movie_id) AS movies_count,
        SUM(CASE 
                WHEN ti.production_year > 2010 THEN 1 
                ELSE 0 
            END) AS recent_movies_count
    FROM 
        actor_hierarchy ah
    JOIN 
        title_info ti ON ti.title_id = ah.movie_id
    GROUP BY 
        ah.actor_id, ah.actor_name
)
SELECT 
    a.actor_id,
    a.actor_name,
    a.movies_count,
    a.recent_movies_count,
    (CASE 
        WHEN a.movies_count = 0 THEN 'No movies' 
        ELSE ROUND((a.recent_movies_count::decimal / a.movies_count) * 100, 2) || '%' 
     END) AS recent_movie_percentage,
    (SELECT 
        STRING_AGG(DISTINCT t.title, ', ') 
     FROM 
        title_info t 
     WHERE 
        t.production_year = (
            SELECT 
                MAX(production_year) 
            FROM 
                title_info 
            WHERE 
                artist_id = a.actor_id
        )
    ) AS latest_movie_title
FROM 
    actor_activity a
WHERE 
    a.recent_movies_count > 0
ORDER BY 
    a.movies_count DESC, a.actor_name
LIMIT 10;

### Explanation:
1. **CTEs**: The query uses Common Table Expressions (CTEs) to break down the data into manageable parts:
   - `actor_hierarchy`: Extracts actors along with their roles and rankings.
   - `title_info`: Gathers information about movies, production year, associated keywords, and companies.
   - `actor_activity`: Aggregates actor data, counting total movies and recent ones.

2. **LEFT JOIN**: It maintains NULLs for parts of the hierarchy when actors may not have movies or titles associated, handling the complexity of relationships through the schema.

3. **Correlated Subquery**: The query computes the title of the latest movie an actor starred in using a correlated subquery.

4. **WINDOW FUNCTIONS**: `ROW_NUMBER` is used to assign ranks to the roles of each actor for specific movies.

5. **CASE Statements**: Employing CASE logic to handle calculations based on conditions, specifically assessing recent movie counts compared to total ones.

6. **STRING_AGG**: Aggregates movie titles into a single string.

7. **COMPLICATED PREDICATES**: Utilizes conditional counting based on production years, which adds complexity to filtering criteria.

8. **NULL Logic**: Handled via `COALESCE` to ensure display values when NULLs are present in the actor names.

This query reflects sophisticated SQL constructs and addresses performance by utilizing aggregates and filtering criteria effectively.
