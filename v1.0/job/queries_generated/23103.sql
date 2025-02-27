WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_details AS (
    SELECT 
        a.person_id, 
        a.name, 
        COUNT(DISTINCT c.movie_id) AS movie_count,
        MIN(t.production_year) AS first_movie_year,
        MAX(t.production_year) AS last_movie_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.person_id, a.name
),
selected_actors AS (
    SELECT 
        ad.person_id, 
        ad.name, 
        ad.movie_count,
        ad.first_movie_year,
        ad.last_movie_year
    FROM 
        actor_details ad
    WHERE 
        ad.movie_count > 5 AND
        (EXTRACT(YEAR FROM CURRENT_DATE) - ad.last_movie_year) <= 10
),
actor_movies AS (
    SELECT 
        sa.name AS actor_name,
        rm.title AS movie_title,
        rm.production_year
    FROM 
        selected_actors sa
    JOIN 
        cast_info ci ON sa.person_id = ci.person_id
    JOIN 
        ranked_movies rm ON ci.movie_id = rm.movie_id
    WHERE 
        rm.year_rank <= 3 
)
SELECT 
    am.actor_name,
    STRING_AGG(am.movie_title, ', ') AS movies,
    COUNT(*) AS title_count,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = sa.person_id)) AS keyword_count,
    (SELECT COUNT(DISTINCT ci.movie_id) FROM cast_info ci WHERE ci.role_id IS NOT NULL AND ci.person_id = sa.person_id) AS distinct_roles_count,
    NULLIF(MAX(am.production_year), MIN(am.production_year)) AS year_range,
    CASE 
        WHEN MAX(am.production_year) = MIN(am.production_year) THEN 'Consistent Year'
        ELSE 'Diverse Year'
    END AS year_diversity
FROM 
    actor_movies am
GROUP BY 
    am.actor_name
HAVING 
    COUNT(*) > 1
ORDER BY 
    title_count DESC NULLS LAST;
