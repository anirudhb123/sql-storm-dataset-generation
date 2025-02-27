WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM title m
    WHERE m.production_year IS NOT NULL
),
actor_roles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_name,
        c.movie_id
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT 
        mv.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mv
    JOIN keyword k ON mv.keyword_id = k.id
    GROUP BY mv.movie_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        MAX(co.name) AS company_name,
        MAX(ct.kind) AS company_type
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ar.actor_name,
    ar.role_name,
    mk.keywords,
    cd.company_name,
    cd.company_type,
    COUNT(DISTINCT ar.actor_name) OVER (PARTITION BY rm.movie_id) AS actor_count,
    CASE 
        WHEN COUNT(DISTINCT ar.actor_name) OVER (PARTITION BY rm.movie_id) > 5 THEN 'Many Actors'
        ELSE 'Few Actors' 
    END AS actor_distribution
FROM ranked_movies rm
LEFT JOIN actor_roles ar ON rm.movie_id = ar.movie_id
LEFT JOIN movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN company_details cd ON rm.movie_id = cd.movie_id
WHERE rm.year_rank <= 10 -- Select top 10 latest movies per year
AND (cd.company_type IS NOT NULL OR mk.keywords IS NOT NULL)
ORDER BY rm.production_year DESC, rm.title;
