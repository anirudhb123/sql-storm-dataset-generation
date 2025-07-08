
WITH ranked_titles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
movies_info AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(m.title, 'Unknown Title') AS title,
        COALESCE(m.production_year, 0) AS production_year,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),
company_summary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(a.actor_count, 0) AS actor_count,
    COALESCE(cs.company_count, 0) AS company_count,
    rt.rank
FROM 
    movies_info m
LEFT JOIN 
    actor_roles a ON m.movie_id = a.movie_id
LEFT JOIN 
    company_summary cs ON m.movie_id = cs.movie_id
JOIN 
    ranked_titles rt ON m.title = rt.title AND m.production_year = rt.production_year
WHERE 
    (m.production_year >= 2000 AND m.production_year <= 2023)
    OR (m.keywords LIKE '%Drama%' OR m.keywords LIKE '%Action%')
ORDER BY 
    m.production_year DESC, rt.rank ASC;
