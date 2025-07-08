
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actors_with_roles AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        COUNT(c.nr_order) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        ak.name, c.movie_id, r.role
),
movies_with_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(aw.role_name, 'No Role Assigned') AS role_name,
    aw.actor_name,
    CASE 
        WHEN aw.role_count IS NULL THEN 'Not In Cast' 
        ELSE 'In Cast' 
    END AS cast_status,
    mwk.keywords
FROM 
    ranked_titles rt
LEFT JOIN 
    actors_with_roles aw ON rt.title_id = aw.movie_id
LEFT JOIN 
    movies_with_keywords mwk ON rt.title_id = mwk.movie_id
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.title;
