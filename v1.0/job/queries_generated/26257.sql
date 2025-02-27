WITH RankedTitles AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_length_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TitleKeyword AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        RankedTitles mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
TitleWithDetails AS (
    SELECT 
        rt.movie_id,
        rt.title,
        rt.production_year,
        tk.keywords,
        ar.actor_count,
        ar.roles
    FROM 
        RankedTitles rt
    LEFT JOIN 
        TitleKeyword tk ON rt.movie_id = tk.movie_id
    LEFT JOIN 
        ActorRoles ar ON rt.movie_id = ar.movie_id
)

SELECT 
    title,
    production_year,
    keywords,
    actor_count,
    roles
FROM 
    TitleWithDetails
WHERE 
    actor_count > 5
ORDER BY 
    production_year DESC, 
    title_length_rank
LIMIT 100;
