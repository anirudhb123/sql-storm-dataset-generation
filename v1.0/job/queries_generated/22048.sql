WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank,
        COUNT(DISTINCT mk.keyword) OVER (PARTITION BY t.id) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
),

ActorDetails AS (
    SELECT 
        a.name,
        ci.movie_id,
        COALESCE(CAST(COUNT(ci.id) AS INTEGER), 0) AS role_count,
        MAX(CASE WHEN c.role_id IS NOT NULL THEN c.role_id ELSE -1 END) AS max_role_id,
        COUNT(DISTINCT ci.nr_order) AS unique_orders
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        role_type c ON ci.role_id = c.id
    GROUP BY 
        a.name, ci.movie_id
),

CompanyStatistics AS (
    SELECT 
        cn.name AS company_name,
        COUNT(mc.movie_id) AS movie_count,
        SUM(CASE WHEN ci.person_id IS NOT NULL THEN 1 ELSE 0 END) AS involved_cast_count
    FROM 
        company_name cn
    LEFT JOIN 
        movie_companies mc ON cn.id = mc.company_id
    LEFT JOIN 
        cast_info ci ON mc.movie_id = ci.movie_id
    GROUP BY 
        cn.name
)

SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COUNT(DISTINCT ad.movie_id) AS actor_movies,
    SUM(Cs.movie_count) AS total_company_movies,
    MAX(ad.role_count) AS max_actor_roles,
    SUM(CASE WHEN ad.unique_orders > 1 THEN 1 ELSE 0 END) AS multi_order_actors
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.title_id = ad.movie_id
LEFT JOIN 
    CompanyStatistics Cs ON ad.movie_id IN (
        SELECT 
            mc.movie_id 
        FROM 
            movie_companies mc 
        INNER JOIN 
            company_name cn ON mc.company_id = cn.id
        WHERE 
            cn.name IS NOT NULL
    )
WHERE 
    rm.rank <= 10 
    AND rm.keyword_count > 0 
    AND (ad.role_count IS NULL OR ad.role_count > 0)
GROUP BY 
    rm.title, rm.production_year
ORDER BY 
    rm.production_year DESC, COUNT(DISTINCT ad.movie_id) DESC
LIMIT 50;
