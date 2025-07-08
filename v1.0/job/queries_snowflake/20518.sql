
WITH Recursive_CTE AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ca.nr_order) AS role_order,
        COALESCE(NULLIF(aka.name, ''), char.name) AS actor_name,
        COALESCE(NULLIF(aka.name, ''), char.name) IS NULL AS is_unknown_actor
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name aka ON ca.person_id = aka.person_id
    LEFT JOIN 
        char_name char ON ca.person_id = char.imdb_id
    WHERE 
        ca.nr_order IS NOT NULL
),
MaxRole_CTE AS (
    SELECT 
        person_id,
        MAX(role_order) AS max_role
    FROM 
        Recursive_CTE
    GROUP BY 
        person_id
),
Filmography AS (
    SELECT 
        r.actor_name,
        r.movie_id,
        m.title AS movie_title,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        mn.note AS movie_note,
        r.role_order,
        MAX(r.role_order) OVER (PARTITION BY r.actor_name) AS max_actor_role
    FROM 
        Recursive_CTE r
    LEFT JOIN 
        aka_title m ON r.movie_id = m.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mn ON mn.movie_id = m.id AND mn.info_type_id IN (SELECT id FROM info_type WHERE info = 'Note')
    WHERE 
        r.role_order = (SELECT max_role FROM MaxRole_CTE WHERE person_id = r.person_id)
)
SELECT 
    f.actor_name,
    COUNT(f.movie_id) AS total_movies,
    LISTAGG(f.movie_title, ', ') WITHIN GROUP (ORDER BY f.movie_title) AS movie_titles,
    LISTAGG(DISTINCT f.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(f.movie_id) > 0 THEN 'Has films' 
        ELSE 'No films' 
    END AS film_status,
    AVG(f.max_actor_role) AS avg_role_position
FROM 
    Filmography f
GROUP BY 
    f.actor_name
HAVING 
    COUNT(f.movie_id) > 1
ORDER BY 
    total_movies DESC
LIMIT 10 OFFSET 5;
