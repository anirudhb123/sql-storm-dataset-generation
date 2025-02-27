WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        r.role,
        COUNT(c.movie_id) AS total_movies
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, r.role
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT p.info, ', ') AS person_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        person_info p ON m.id = p.person_id
    GROUP BY 
        m.title, m.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ar.total_movies, 0) AS actor_movie_count,
    md.company_count,
    md.person_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON ar.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = (SELECT id FROM aka_title WHERE title = rm.title))
LEFT JOIN 
    MovieDetails md ON md.title = rm.title
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
