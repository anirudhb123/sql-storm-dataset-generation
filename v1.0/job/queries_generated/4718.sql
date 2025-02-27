WITH ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),
CompanyContributions AS (
    SELECT 
        c.id AS company_id, 
        cn.name AS company_name,
        COUNT(m.movie_id) AS total_movies
    FROM 
        company_name cn
    JOIN 
        movie_companies m ON cn.id = m.company_id
    JOIN 
        aka_title t ON m.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        c.id, cn.name
),
RoleStatistics AS (
    SELECT 
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
)
SELECT 
    am.actor_name,
    am.movie_title,
    am.production_year,
    cc.company_name,
    cc.total_movies,
    rs.actor_count,
    rs.movie_count
FROM 
    ActorMovies am
LEFT JOIN 
    movie_companies mc ON am.production_year = mc.movie_id
LEFT JOIN 
    CompanyContributions cc ON mc.company_id = cc.company_id
JOIN 
    RoleStatistics rs ON am.movie_rank = rs.role_id
WHERE 
    am.movie_rank <= 3
    AND cc.total_movies IS NOT NULL
UNION ALL
SELECT 
    a.name,
    t.title,
    t.production_year,
    NULL AS company_name,
    NULL AS total_movies,
    NULL AS actor_count,
    NULL AS movie_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
WHERE 
    a.name IS NULL
    AND t.production_year < 2000
ORDER BY 
    production_year DESC, actor_name;
