
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        LISTAGG(DISTINCT rt.role, ', ') WITHIN GROUP (ORDER BY rt.role) AS roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    AN.name AS actor_name,
    RT.title,
    RT.production_year,
    ARC.movie_count,
    COALESCE(MWK.keywords, ARRAY_CONSTRUCT()) AS keywords
FROM 
    aka_name AN
JOIN 
    cast_info CI ON AN.person_id = CI.person_id
JOIN 
    RankedTitles RT ON CI.movie_id = RT.title_id
JOIN 
    ActorRoleCounts ARC ON ARC.person_id = AN.person_id
LEFT JOIN 
    MoviesWithKeywords MWK ON MWK.movie_id = CI.movie_id
WHERE 
    ARC.movie_count > 5
    AND RT.title_rank = 1
GROUP BY 
    AN.name, RT.title, RT.production_year, ARC.movie_count, MWK.keywords
ORDER BY 
    RT.production_year DESC, 
    AN.name;
