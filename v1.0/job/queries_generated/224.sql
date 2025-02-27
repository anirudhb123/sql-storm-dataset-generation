WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        *
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorDetails AS (
    SELECT
        p.person_id,
        p.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name p
    JOIN 
        cast_info c ON p.person_id = c.person_id
    GROUP BY 
        p.person_id, p.name
)
SELECT 
    tm.title,
    tm.production_year,
    ad.name AS actor_name,
    ad.movie_count,
    COALESCE(NULLIF(ad.movie_count, 0), 'No Movies') AS movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    ActorDetails ad ON ad.person_id IN (
        SELECT 
            DISTINCT c.person_id 
        FROM 
            cast_info c 
        WHERE 
            c.movie_id = tm.id
    )
ORDER BY 
    tm.production_year DESC, tm.actor_count DESC;
