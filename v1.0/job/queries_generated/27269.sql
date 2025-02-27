WITH ActorMovie AS (
    SELECT 
        a.id as actor_id, 
        a.name as actor_name, 
        t.title as movie_title, 
        t.production_year, 
        r.role as role
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year >= 2000
),

MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

ActorDetails AS (
    SELECT 
        am.actor_id, 
        am.actor_name, 
        am.movie_title, 
        am.production_year, 
        am.role,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        ActorMovie am
    LEFT JOIN 
        MovieKeywords mk ON am.movie_title = mk.movie_id
)

SELECT 
    actor_id, 
    actor_name, 
    movie_title, 
    production_year, 
    role, 
    keywords
FROM 
    ActorDetails
ORDER BY 
    production_year DESC, 
    actor_name;
