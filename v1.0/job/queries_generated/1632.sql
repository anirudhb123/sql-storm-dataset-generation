WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
actor_info AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS total_movies,
        AVG(ci.nr_order) AS avg_order
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        complete_cast cc ON c.movie_id = cc.movie_id
    LEFT JOIN 
        movie_info mi ON cc.movie_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        a.id
),
company_stats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cmp.id) AS total_companies,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ai.actor_name,
    ai.total_movies,
    coalesce(cs.total_companies, 0) AS total_companies,
    coalesce(cs.company_names, 'No companies') AS company_names
FROM 
    ranked_movies rm
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    actor_info ai ON ci.person_id = ai.actor_id
LEFT JOIN 
    company_stats cs ON rm.movie_id = cs.movie_id
WHERE 
    ai.total_movies > 5
ORDER BY 
    rm.production_year DESC, ai.avg_order DESC;
