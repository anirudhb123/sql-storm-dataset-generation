WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        c.person_id, 
        c.movie_id,
        COUNT(*) AS movie_count,
        LISTAGG(DISTINCT t.title, ', ') WITHIN GROUP (ORDER BY t.title) AS all_movies
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        c.person_id, c.movie_id
),
subquery_movies AS (
    SELECT 
        movie_id,
        MAX(info_text) AS info_text
    FROM (
        SELECT 
            m.movie_id,
            CASE 
                WHEN m.info IS NULL THEN t.title || ' is underrated' 
                ELSE m.info 
            END AS info_text
        FROM 
            movie_info m
        LEFT JOIN 
            aka_title t ON m.movie_id = t.id
        WHERE 
            m.note IS NOT NULL
    ) AS temp
    GROUP BY movie_id
),
final_result AS (
    SELECT 
        a.person_id,
        n.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        COALESCE(SUM(CASE WHEN a.movie_count > 1 THEN a.movie_count ELSE 0 END), 0) AS multiple_roles,
        STRING_AGG(DISTINCT t.title, '; ') AS titles_with_roles
    FROM 
        actor_movies a
    JOIN 
        aka_name n ON a.person_id = n.person_id
    LEFT JOIN 
        subquery_movies sm ON a.movie_id = sm.movie_id
    LEFT JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        n.name IS NOT NULL AND (n.name NOT LIKE '%John%' OR n.name NOT LIKE '%Doe%')
    GROUP BY 
        a.person_id, n.name
)
SELECT 
    fr.actor_name,
    fr.total_movies,
    fr.multiple_roles,
    fr.titles_with_roles,
    COUNT(DISTINCT t.title) AS unique_titles,
    MAX(t.production_year) AS latest_year_featured,
    MIN(CASE WHEN t.production_year < 2000 THEN t.production_year END) AS first_pre_2000
FROM 
    final_result fr
LEFT JOIN 
    aka_title t ON fr.titles_with_roles LIKE '%' || t.title || '%'
GROUP BY 
    fr.actor_name, fr.total_movies, fr.multiple_roles, fr.titles_with_roles
HAVING 
    COUNT(DISTINCT t.title) > 1 AND MAX(t.production_year) IS NOT NULL
ORDER BY 
    fr.actor_name ASC;
