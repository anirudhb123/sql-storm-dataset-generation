WITH ranked_movies AS (
    SELECT 
        at.title, 
        at.production_year, 
        COALESCE(ct.kind, 'Unknown') AS company_type,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        at.id, at.title, at.production_year, ct.kind
),
movies_with_roles AS (
    SELECT 
        at.title,
        COUNT(DISTINCT ci.role_id) AS role_count,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        at.id, at.title
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_type,
    mw.actor_count,
    mw.role_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = at.id) AS info_count,
    CASE 
        WHEN mw.actor_count > 0 THEN mw.role_count * 1.0 / mw.actor_count 
        ELSE NULL 
    END AS avg_roles_per_actor
FROM 
    ranked_movies rm
JOIN 
    movies_with_roles mw ON rm.title = mw.title
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    avg_roles_per_actor DESC NULLS LAST;
