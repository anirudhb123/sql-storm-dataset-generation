WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        t.season_nr,
        t.episode_nr,
        1 AS depth
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    UNION ALL
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.episode_of_id,
        t.season_nr,
        t.episode_nr,
        th.depth + 1
    FROM 
        aka_title t
    JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id
),

averaged_casting AS (
    SELECT 
        ci.movie_id,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),

ranked_movies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COALESCE(b.avg_roles, 0) AS avg_roles,
        RANK() OVER (ORDER BY COALESCE(b.avg_roles, 0) DESC, a.production_year DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        averaged_casting b ON a.id = b.movie_id
)

SELECT 
    r.title, 
    r.production_year, 
    r.avg_roles, 
    th.depth,
    CASE 
        WHEN r.avg_roles IS NULL THEN 'No roles cast'
        ELSE CAST(r.avg_roles AS VARCHAR) || ' roles cast'
    END AS role_status,
    STRING_AGG(DISTINCT n.name, ', ') FILTER (WHERE n.name IS NOT NULL) AS cast_names
FROM 
    ranked_movies r
LEFT JOIN 
    cast_info ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    aka_name n ON ci.person_id = n.person_id
LEFT JOIN 
    title_hierarchy th ON r.title_id = th.title_id
WHERE 
    r.rank <= 10 
    AND (EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = r.movie_id 
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
        ) OR r.production_year >= 2000)
GROUP BY 
    r.title, r.production_year, r.avg_roles, th.depth
ORDER BY 
    r.rank;
