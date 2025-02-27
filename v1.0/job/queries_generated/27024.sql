WITH ActorMovieStats AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN 
        title t ON ci.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        a.id, a.name
),
TopActors AS (
    SELECT 
        actor_id, 
        actor_name, 
        movie_count, 
        movie_titles,
        keywords,
        company_types,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorMovieStats
)
SELECT 
    rank, 
    actor_id, 
    actor_name, 
    movie_count, 
    movie_titles,
    keywords,
    company_types
FROM 
    TopActors
WHERE 
    rank <= 10
ORDER BY 
    rank;
