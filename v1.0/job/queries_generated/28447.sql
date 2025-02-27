WITH ActorMovieCount AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.id, a.name
), 
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        movie_count
    FROM 
        ActorMovieCount
    WHERE 
        movie_count > 5
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        mt.kind AS movie_type,
        GROUP_CONCAT(DISTINCT cn.name) AS companies_involved
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        kind_type mt ON t.kind_id = mt.id
    GROUP BY 
        t.id, mt.kind, t.production_year
)
SELECT 
    ta.actor_name,
    ta.movie_count,
    md.movie_title,
    md.production_year,
    md.movie_type,
    md.companies_involved
FROM 
    TopActors ta
JOIN 
    cast_info ci ON ta.actor_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    MovieDetails md ON t.id = md.id
ORDER BY 
    ta.movie_count DESC, 
    md.production_year DESC;
