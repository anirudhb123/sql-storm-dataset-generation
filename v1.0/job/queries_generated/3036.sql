WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        COALESCE(SUM(mci.company_id), 0) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mci ON t.id = mci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), ActorDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(ci.id) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.id) DESC) AS rn
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
), TopActors AS (
    SELECT 
        movie_id,
        actor_name,
        role_count
    FROM 
        ActorDetails
    WHERE 
        rn = 1
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.company_count,
    ta.actor_name,
    COALESCE(ta.role_count, 0) AS top_actor_role_count
FROM 
    MovieDetails md
LEFT JOIN 
    TopActors ta ON md.title_id = ta.movie_id
WHERE 
    md.company_count > 3
ORDER BY 
    md.production_year DESC, 
    md.title;
