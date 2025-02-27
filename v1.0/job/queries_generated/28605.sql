WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS role_name,
        c.kind AS comp_kind,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        title t
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, a.name, r.role, t.production_year, c.kind
), ActorMovieCount AS (
    SELECT
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
)

SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    amc.movie_count,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    ActorMovieCount amc ON amc.actor_name = md.actor_name
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
