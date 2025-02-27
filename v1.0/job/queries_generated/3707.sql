WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        c.person_id,
        r.movie_id,
        COALESCE(ka.name, 'Unknown') AS actor_name,
        COUNT(DISTINCT r.movie_id) AS movie_count
    FROM 
        cast_info c
    INNER JOIN 
        RankedMovies r ON c.movie_id = r.movie_id
    LEFT JOIN 
        aka_name ka ON c.person_id = ka.person_id
    GROUP BY 
        c.person_id, r.movie_id, ka.name
),
MovieRoles AS (
    SELECT 
        m.title,
        COALESCE(ct.kind, 'Other') AS company_type,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        movie_companies mc
    INNER JOIN 
        aka_title m ON mc.movie_id = m.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_info c ON mc.movie_id = c.movie_id
    GROUP BY 
        m.title, ct.kind, m.production_year
)
SELECT 
    a.actor_name,
    m.title,
    m.production_year,
    m.cast_count,
    CASE 
        WHEN m.cast_count > 5 THEN 'Large Cast'
        WHEN m.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    RANK() OVER (ORDER BY m.production_year DESC, m.cast_count DESC) AS rank
FROM 
    ActorMovies a
JOIN 
    MovieRoles m ON a.movie_id = m.movie_id
WHERE 
    m.production_year >= 2000
    AND (a.movie_count > 1 OR a.actor_name IS NULL)
ORDER BY 
    m.production_year DESC, rank, a.actor_name;
