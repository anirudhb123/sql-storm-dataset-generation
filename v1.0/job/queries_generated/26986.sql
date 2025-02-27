WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title AS a
    LEFT JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
),
ActorStats AS (
    SELECT 
        ak.person_id,
        COUNT(DISTINCT mk.movie_id) AS total_movies,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', m.production_year, ')') ORDER BY m.production_year DESC) AS movie_titles
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        RankedMovies AS m ON ci.movie_id = m.movie_id
    LEFT JOIN 
        name AS a ON ak.person_id = a.imdb_id
    GROUP BY 
        ak.person_id
),
TopActors AS (
    SELECT 
        p.name AS actor_name, 
        p.id AS actor_id, 
        s.total_movies,
        s.movie_titles
    FROM 
        aka_name AS p
    JOIN 
        ActorStats AS s ON p.person_id = s.person_id
    WHERE 
        s.total_movies >= 5
    ORDER BY 
        s.total_movies DESC
    LIMIT 10
)
SELECT 
    ta.actor_name,
    ta.total_movies,
    ta.movie_titles,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM 
    TopActors AS ta
LEFT JOIN 
    movie_companies AS mc ON ta.actor_id = mc.movie_id
GROUP BY 
    ta.actor_name, ta.total_movies, ta.movie_titles
ORDER BY 
    production_companies DESC;
