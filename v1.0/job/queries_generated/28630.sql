WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        m.id
),
TopRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.kind_id,
        mi.keywords
    FROM 
        RankedTitles rt
    JOIN 
        MovieInfo mi ON rt.title_id = mi.movie_id
    WHERE 
        rt.title_rank <= 5 -- Selecting top 5 titles per year
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.person_role_id = r.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    tr.title,
    tr.production_year,
    tr.keywords,
    ar.actor_count,
    ar.roles
FROM 
    TopRankedTitles tr
LEFT JOIN 
    ActorRoles ar ON tr.title_id = ar.movie_id
ORDER BY 
    tr.production_year DESC, 
    tr.title;
