WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        ci.person_id,
        t.production_year,
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'actor')
    GROUP BY 
        ci.person_id, 
        t.production_year
),
actor_names AS (
    SELECT 
        a.person_id,
        STRING_AGG(a.name, ', ') AS actor_names
    FROM 
        aka_name a
    GROUP BY 
        a.person_id
),
combined_info AS (
    SELECT 
        a.person_id,
        an.actor_names,
        am.production_year,
        am.movie_count,
        rt.title AS rank_title,
        rt.year_rank
    FROM 
        actor_movies am
    JOIN 
        actor_names an ON am.person_id = an.person_id
    LEFT JOIN 
        ranked_titles rt ON am.production_year = rt.production_year AND (am.movie_count > 1 OR rt.year_rank = 1)
)
SELECT 
    ci.actor_names,
    ci.production_year,
    ci.movie_count,
    COALESCE(ci.rank_title, 'No Top Title') AS top_title,
    ci.year_rank,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN mi.info LIKE '%Award%' THEN 1 ELSE 0 END) AS award_count
FROM 
    combined_info ci
LEFT JOIN 
    movie_companies mc ON mc.movie_id IN (SELECT t.id FROM title t WHERE t.production_year = ci.production_year)
LEFT JOIN 
    movie_info mi ON mi.movie_id IN (SELECT t.id FROM title t WHERE t.production_year = ci.production_year)
GROUP BY 
    ci.actor_names, 
    ci.production_year, 
    ci.movie_count, 
    ci.rank_title, 
    ci.year_rank
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    ci.production_year DESC, 
    ci.movie_count DESC;
