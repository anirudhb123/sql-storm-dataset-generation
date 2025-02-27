WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, LENGTH(at.title) DESC) AS title_rank,
        COUNT(cm.company_id) AS company_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_companies cm ON at.id = cm.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
ActorRoleCounts AS (
    SELECT 
        ka.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count,
        MAX(ki.keyword) FILTER (WHERE ki.keyword IS NOT NULL) AS main_keyword
    FROM 
        aka_name ka
    LEFT JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        ka.person_id
),
MoviesWithTwoOrMoreRoles AS (
    SELECT 
        rk.movie_title, 
        rk.production_year,
        ar.person_id
    FROM 
        RankedMovies rk
    INNER JOIN 
        ActorRoleCounts ar ON ar.role_count >= 2
)
SELECT 
    m.movie_title,
    m.production_year,
    COUNT(DISTINCT ar.person_id) AS actors_with_multiple_roles,
    STRING_AGG(DISTINCT ar.main_keyword, ', ') AS keywords_list
FROM 
    MoviesWithTwoOrMoreRoles m
LEFT JOIN 
    ActorRoleCounts ar ON m.person_id = ar.person_id
GROUP BY 
    m.movie_title, m.production_year
HAVING 
    COUNT(DISTINCT ar.person_id) > 5 
ORDER BY 
    m.production_year DESC, 
    actors_with_multiple_roles DESC
LIMIT 10;
