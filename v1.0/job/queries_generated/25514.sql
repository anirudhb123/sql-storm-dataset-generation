WITH MovieCastDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ct.kind AS role_type,
        COALESCE(COUNT(ci.id), 0) AS role_count
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        role_type AS ct ON ci.role_id = ct.id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        t.id, ak.name, t.title, t.production_year, ct.kind
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        role_type,
        role_count,
        RANK() OVER (PARTITION BY production_year ORDER BY role_count DESC) AS rank
    FROM 
        MovieCastDetails
)

SELECT 
    production_year,
    movie_title,
    actor_name,
    role_type,
    role_count
FROM 
    TopMovies
WHERE 
    rank <= 3
ORDER BY 
    production_year, rank;
