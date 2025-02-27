WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(e.season_nr, 0) AS season_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        title e ON at.episode_of_id = e.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id, e.season_nr
),
actor_role_counts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        COUNT(DISTINCT c.role_id) AS role_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
person_info_summary AS (
    SELECT 
        p.id AS person_id,
        p.name,
        ai.movie_count,
        ai.role_count,
        ai.note_count,
        ROW_NUMBER() OVER (ORDER BY ai.movie_count DESC, ai.role_count DESC) AS person_rank
    FROM 
        aka_name p
    JOIN 
        actor_role_counts ai ON p.person_id = ai.person_id
)
SELECT 
    th.title,
    th.production_year,
    th.company_count,
    th.season_count,
    p.name AS actor_name,
    p.movie_count,
    p.role_count,
    p.note_count,
    COALESCE(k.keyword, 'No Keywords') AS keywords
FROM 
    title_hierarchy th
INNER JOIN 
    movie_keyword mk ON th.title_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info_summary p ON p.movie_count > 5 AND p.person_rank <= 10
WHERE 
    th.production_year BETWEEN 2000 AND 2023
    AND th.company_count > 1
    AND (th.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%') OR th.season_count >= 1)
ORDER BY 
    th.production_year DESC, th.title, p.movie_count DESC;
