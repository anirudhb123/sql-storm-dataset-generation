WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        p.id AS person_id,
        p.name,
        rt.role AS role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ac.name AS actor_name,
        ar.role,
        kt.keyword
    FROM 
        RankedTitles mt
    LEFT JOIN 
        ActorRoles ar ON mt.title_id = ar.movie_id
    LEFT JOIN 
        aka_title kt ON mt.title_id = kt.id
)
SELECT 
    md.title AS Title,
    md.production_year AS Production_Year,
    md.actor_name AS Actor,
    md.role AS Actor_Role,
    COUNT(md.keyword) AS Keyword_Count
FROM 
    MovieDetails md
WHERE 
    md.role IS NOT NULL
GROUP BY 
    md.title, md.production_year, md.actor_name, md.role
ORDER BY 
    md.production_year DESC, COUNT(md.keyword) DESC;
