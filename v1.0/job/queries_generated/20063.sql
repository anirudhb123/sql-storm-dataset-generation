WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role AS person_role,
        COALESCE(MAX(CASE WHEN ci.kind IS NOT NULL THEN ci.kind END), 'Unknown') AS company_type,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    LEFT JOIN 
        comp_cast_type ci ON mc.company_type_id = ci.id
    LEFT JOIN 
        movie_keyword k ON c.movie_id = k.movie_id
    GROUP BY 
        c.movie_id, c.person_id, r.role
),
TopActors AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ca.person_role, ', ') AS roles
    FROM 
        CastDetails ca
    GROUP BY 
        ca.person_id
    HAVING 
        COUNT(DISTINCT ca.movie_id) > 2
),
GenreStats AS (
    SELECT 
        t.production_year,
        COUNT(DISTINCT t.id) AS movie_count,
        COUNT(DISTINCT kc.keyword) AS genre_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.production_year
)
SELECT 
    RM.title,
    RM.production_year,
    COALESCE(TA.movie_count, 0) AS actor_movie_count,
    COALESCE(TA.roles, 'No roles assigned') AS actor_roles,
    GS.movie_count AS genre_movie_count,
    GS.genre_count
FROM 
    RankedMovies RM
LEFT JOIN 
    TopActors TA ON RM.movie_id = TA.movie_id
LEFT JOIN 
    GenreStats GS ON RM.production_year = GS.production_year
WHERE 
    (RM.production_year BETWEEN 2000 AND 2020)
    AND (GS.genre_count IS NULL OR GS.genre_count > 10)
ORDER BY 
    RM.production_year DESC, RM.title ASC;

This query performs the following complex operations:

1. A Common Table Expression (CTE) `RankedMovies` ranks movies by their title within each production year.
2. Another CTE `CastDetails` aggregates the casting information, linking to the role types and counting keywords associated with each movie.
3. The `TopActors` CTE identifies actors with more than two movie roles and aggregates their roles into a string.
4. The `GenreStats` CTE counts the number of movies and genres associated with each production year.
5. The final `SELECT` statement combines the results from these CTEs with multiple outer joins and applies various filtering conditions based on production year and genre presence.
6. It uses `COALESCE` to handle potential NULL values elegantly, ensuring output consistency. 

This illustrates a more intricate SQL structure suitable for performance benchmarking while handling multiple SQL constructs.
