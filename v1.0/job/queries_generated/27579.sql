WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),
ActorsWithMultipleRoles AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id
    HAVING 
        COUNT(DISTINCT ci.role_id) > 1
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
)
SELECT 
    rt.actor_name,
    rt.movie_title,
    rt.production_year,
    mwk.keywords,
    ar.role_count
FROM 
    RankedTitles rt
JOIN 
    MoviesWithKeywords mwk ON rt.movie_title = mwk.title
JOIN 
    ActorsWithMultipleRoles ar ON rt.actor_name IN (SELECT a.name FROM aka_name a WHERE a.person_id = ar.person_id)
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, ar.role_count DESC;
