-- This query benchmarks string processing by extracting and analyzing 
-- movie titles along with associated details about the cast, 
-- filtering based on specific criteria, and performing 
-- complex joins and aggregations.

WITH title_data AS (
    SELECT 
        t.id AS title_id,
        t.title AS title,
        t.production_year,
        k.keyword AS keyword,
        n.name AS actor_name,
        n.gender,
        ci.note AS role_note
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    WHERE 
        t.production_year >= 2000 AND 
        (k.keyword LIKE '%Action%' OR k.keyword LIKE '%Comedy%')
),
actor_gender_count AS (
    SELECT 
        actor_name,
        gender,
        COUNT(*) AS appearance_count
    FROM 
        title_data
    GROUP BY 
        actor_name, gender
),
top_actors AS (
    SELECT 
        actor_name,
        gender,
        appearance_count,
        RANK() OVER (PARTITION BY gender ORDER BY appearance_count DESC) AS rank
    FROM 
        actor_gender_count
)

SELECT 
    t.title,
    t.production_year,
    a.actor_name,
    a.gender,
    a.appearance_count
FROM 
    title_data t
JOIN 
    top_actors a ON t.actor_name = a.actor_name
WHERE 
    a.rank <= 5
ORDER BY 
    t.production_year DESC, a.appearance_count DESC;
The above SQL query performs the following operations:

1. **Common Table Expression (CTE)**: `title_data` gathers movie titles from the `title` table joined with relevant tables (`movie_keyword`, `keyword`, `complete_cast`, `cast_info`, and `aka_name`) to filter for movies from the year 2000 onwards that belong to the genres "Action" or "Comedy".

2. **Aggregation**: Another CTE, `actor_gender_count`, computes the count of appearances for actors across different genders.

3. **Ranking**: The `top_actors` CTE ranks these appearances to identify the top 5 actors per gender based on their appearance count.

4. **Final Selection**: The final select statement consolidates the data, outputting the title, production year, actor name, gender, and appearance count for the top actors in the specified genres.

This query tests SQL processing capabilities with string manipulation and joins across multiple tables with filtering and ranking involved.
