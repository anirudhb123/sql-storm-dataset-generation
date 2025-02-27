WITH ranked_movies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_year,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY t.id) AS company_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
),
recent_actor_movies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        company_count
    FROM ranked_movies
    WHERE rank_year <= 3 
    AND (company_count > 2 OR production_year > 2000)
),
actors_info AS (
    SELECT 
        ra.actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM recent_actor_movies ra
    JOIN cast_info ci ON ra.movie_title = ci.movie_id
    JOIN aka_title t ON ci.movie_id = t.id
    GROUP BY ra.actor_name
)
SELECT 
    a.actor_name,
    a.movie_count,
    COALESCE(a.titles, 'No titles available') AS titles,
    COUNT(DISTINCT ci.person_role_id) AS distinct_roles,
    MAX(CASE 
        WHEN a.movie_count >= 5 THEN 'Frequent Actor'
        ELSE 'Occasional Actor' 
    END) AS actor_category
FROM actors_info a
LEFT JOIN cast_info ci ON a.actor_name = (SELECT name FROM aka_name WHERE person_id = ci.person_id)
WHERE LOWER(a.actor_name) NOT LIKE '%naomi%'
GROUP BY a.actor_name, a.movie_count, a.titles
ORDER BY a.movie_count DESC NULLS LAST;

-- Note: Adjustments to column names might be necessary to fit actual relationships, 
-- especially in JOIN conditions or column selections to ensure correct query execution.
