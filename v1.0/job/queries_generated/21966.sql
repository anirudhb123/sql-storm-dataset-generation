WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        ca.person_id,
        ct.kind AS role,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM cast_info c
    JOIN comp_cast_type ct ON c.person_role_id = ct.id
    GROUP BY ca.person_id, ct.kind
),
title_keywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN aka_title mt ON mk.movie_id = mt.id
    GROUP BY mt.movie_id
),
actor_info AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS note_count
    FROM aka_name ka
    LEFT JOIN cast_info c ON ka.person_id = c.person_id
    GROUP BY ka.person_id, ka.name
)
SELECT 
    a.name AS actor_name,
    a.total_movies,
    COALESCE(tk.keywords, 'No Keywords') AS keywords,
    rt.title,
    rt.production_year,
    rt.title_rank,
    ai.role,
    (SELECT COUNT(DISTINCT m.id) 
     FROM aka_title m 
     JOIN movie_keyword mk ON m.id = mk.movie_id 
     WHERE mk.keyword IN ('Action', 'Thriller')) AS action_thriller_count
FROM actor_info a
LEFT JOIN actor_movies ai ON a.person_id = ai.person_id
LEFT JOIN title_keywords tk ON ai.movie_id = tk.movie_id
JOIN ranked_titles rt ON ai.movie_count > 5 AND a.total_movies > 10
WHERE rt.title_rank BETWEEN 1 AND 3
ORDER BY a.total_movies DESC, rt.production_year DESC NULLS LAST;

