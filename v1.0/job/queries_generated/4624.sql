WITH RankingCTE AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS role_rank,
        COUNT(DISTINCT c.role_id) OVER (PARTITION BY t.id) AS total_roles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        role_rank,
        total_roles,
        RANK() OVER (PARTITION BY production_year ORDER BY total_roles DESC) AS movie_rank
    FROM 
        RankingCTE
    WHERE 
        year(production_year) BETWEEN 2000 AND 2023
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    role_rank,
    total_roles,
    movie_rank
FROM 
    FilteredMovies
WHERE 
    movie_rank <= 10
ORDER BY 
    production_year DESC, 
    movie_rank;
