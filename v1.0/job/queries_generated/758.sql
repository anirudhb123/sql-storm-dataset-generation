WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),

MovieGenres AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT g.kind, ', ') AS genres
    FROM 
        aka_title m
    JOIN kind_type g ON m.kind_id = g.id
    GROUP BY 
        m.movie_id
),

ActorInfo AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(c.movie_id) AS movies_count,
        STRING_AGG(DISTINCT m.title, ', ') AS movies_list
    FROM 
        aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title m ON c.movie_id = m.id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(c.movie_id) > 5
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS companies_count,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies_list
    FROM 
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mg.genres, 'No Genre') AS genres,
    ai.name AS actor_name,
    ai.movies_count,
    ai.movies_list,
    cs.companies_count,
    cs.companies_list
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
LEFT JOIN 
    ActorInfo ai ON rm.movie_id IN (SELECT c.movie_id FROM cast_info c WHERE c.person_id = ai.person_id)
LEFT JOIN 
    CompanyStats cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.year_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC
LIMIT 50;
