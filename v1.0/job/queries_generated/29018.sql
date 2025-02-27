WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
ActorDetails AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        r.role AS role_type,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        p.id, p.name, r.role
),
TopActors AS (
    SELECT 
        actor_name,
        role_type,
        movie_count,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        ActorDetails
    WHERE 
        movie_count > 5
),
FinalResult AS (
    SELECT 
        rt.movie_title,
        rt.production_year,
        ta.actor_name,
        ta.role_type,
        ta.movie_count
    FROM 
        RankedTitles rt
    JOIN 
        movie_info mi ON rt.production_year = mi.movie_id
    JOIN 
        TopActors ta ON mi.movie_id = rt.movie_id
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    role_type,
    movie_count
FROM 
    FinalResult
WHERE 
    title_rank = 1
ORDER BY 
    production_year DESC, actor_name;
