WITH AggregatedRatings AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year AS movie_year,
        COUNT(c.id) AS roles_count
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND t.production_year >= 2000
    GROUP BY 
        a.name, t.title, t.production_year
),
TopActors AS (
    SELECT 
        actor_name,
        SUM(roles_count) AS total_roles
    FROM 
        AggregatedRatings
    GROUP BY 
        actor_name
    ORDER BY 
        total_roles DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        kc.keyword AS keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    ta.actor_name,
    COUNT(md.title) AS movies_participated,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords
FROM 
    TopActors ta
JOIN 
    AggregatedRatings ar ON ta.actor_name = ar.actor_name
JOIN 
    MovieDetails md ON ar.movie_title = md.title
GROUP BY 
    ta.actor_name
ORDER BY 
    movies_participated DESC;