WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS production_year_rank
    FROM 
        aka_title m
    WHERE 
        m.title IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
SelectedMovies AS (
    SELECT 
        DISTINCT movie_id 
    FROM 
        ActorRoles
    WHERE 
        role_rank = 1 
        AND actor_name LIKE 'A%' -- Actors whose names start with 'A'
),
TitleKeyword AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
),
FinalResult AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(kw.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT a.actor_name) AS num_actors
    FROM 
        RankedMovies m
    LEFT JOIN 
        TitleKeyword kw ON m.movie_id = kw.movie_id
    LEFT JOIN 
        ActorRoles a ON m.movie_id = a.movie_id
    WHERE 
        m.production_year > 2000 
        AND m.production_year_rank < 5
    GROUP BY 
        m.movie_id, m.title, m.production_year, kw.keywords
    HAVING 
        COUNT(DISTINCT a.actor_name) > 2
    ORDER BY 
        m.production_year DESC, num_actors DESC
)

SELECT 
    *,
    CASE 
        WHEN num_actors IS NULL THEN 'No Actor Information'
        ELSE 'Actor Count Present'
    END AS actor_info_status
FROM 
    FinalResult
WHERE 
    keywords IS NULL OR keywords LIKE '%Drama%' -- Including some bizarre logic for keyword filtering 
ORDER BY 
    production_year DESC, title ASC;
