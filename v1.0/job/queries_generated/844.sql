WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
HighestRanked AS (
    SELECT 
        production_year, 
        title 
    FROM 
        RankedMovies 
    WHERE 
        rank = 1
),
ActorRoleCount AS (
    SELECT 
        ci.movie_id,
        r.role AS actor_role,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
MoviesWithRoles AS (
    SELECT 
        ht.title, 
        a.production_year,
        COALESCE(arc.actor_role, 'Unknown') AS actor_role,
        COALESCE(arc.num_actors, 0) AS num_actors
    FROM 
        HighestRanked ht
    JOIN 
        aka_title a ON ht.title = a.title AND ht.production_year = a.production_year
    LEFT JOIN 
        ActorRoleCount arc ON a.id = arc.movie_id
)
SELECT 
    mw.title, 
    mw.production_year, 
    mw.actor_role,
    mw.num_actors,
    COALESCE(cn.name, 'No Company') AS company_name,
    COUNT(DISTINCT mc.company_id) AS total_companies
FROM 
    MoviesWithRoles mw
LEFT JOIN 
    movie_companies mc ON mw.production_year = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    mw.title, mw.production_year, mw.actor_role, cn.name
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    mw.production_year DESC, mw.num_actors DESC;
