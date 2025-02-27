WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
cast_with_titles AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        r.role,
        rt.title AS movie_title,
        rt.production_year
    FROM cast_info c
    INNER JOIN aka_name a ON c.person_id = a.person_id
    INNER JOIN role_type r ON c.role_id = r.id
    INNER JOIN ranked_titles rt ON c.movie_id = rt.title_id
)
SELECT 
    cwt.actor_name,
    cwt.movie_title,
    cwt.production_year,
    COUNT(*) OVER (PARTITION BY cwt.production_year) AS total_cast_in_year,
    SUM(CASE WHEN cwt.role = 'actor' THEN 1 ELSE 0 END) OVER (PARTITION BY cwt.production_year) AS total_actors_in_year
FROM cast_with_titles cwt
WHERE cwt.year_rank <= 5
ORDER BY cwt.production_year DESC, cwt.actor_name;
