
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000 
        AND t.title IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT COALESCE(a.name, 'Unknown Actor')) AS actors_list
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_count,
        ar.actors_list,
        CASE 
            WHEN rm.rank_per_year = 1 THEN 'First'
            WHEN rm.rank_per_year = total_movies_per_year THEN 'Last'
            ELSE NULL
        END AS position_desc
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_count,
    md.actors_list,
    md.position_desc,
    (
        SELECT LISTAGG(DISTINCT k.keyword, ', ') 
        FROM movie_keyword mk 
        JOIN keyword k ON mk.keyword_id = k.id 
        WHERE mk.movie_id = md.movie_id
    ) AS keywords,
    (
        SELECT 
            COUNT(DISTINCT mc.company_id) 
        FROM 
            movie_companies mc 
        WHERE 
            mc.movie_id = md.movie_id 
            AND mc.note IS NOT NULL
    ) AS company_count
FROM 
    MovieDetails md
WHERE 
    md.actor_count > 0
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC 
LIMIT 10;
