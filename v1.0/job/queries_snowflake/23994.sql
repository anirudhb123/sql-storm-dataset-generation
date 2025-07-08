
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE
        t.production_year IS NOT NULL
        AND t.title NOT LIKE '%Untitled%'
),
actor_roles AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        r.role AS role_name,
        COUNT(CASE WHEN c.note IS NOT NULL THEN 1 END) AS speaking_roles_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL 
    GROUP BY 
        a.name, c.movie_id, r.role
),
company_counts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
movie_keywords AS (
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
    rm.movie_id,
    rm.title,
    rm.production_year,
    actor_roles.actor_name,
    actor_roles.role_name,
    actor_roles.speaking_roles_count,
    COALESCE(cc.company_count, 0) AS company_count,
    mk.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_roles ON rm.movie_id = actor_roles.movie_id
LEFT JOIN 
    company_counts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rn = 1
    AND (actor_roles.speaking_roles_count > 0 OR actor_roles.actor_name IS NULL)
ORDER BY 
    rm.production_year DESC, 
    actor_roles.speaking_roles_count DESC
LIMIT 50;
