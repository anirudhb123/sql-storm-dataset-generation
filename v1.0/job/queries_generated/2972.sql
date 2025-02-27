WITH RecentMovies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.kind_id 
    FROM 
        aka_title mt 
    WHERE 
        mt.production_year >= 2010
), ActorRoles AS (
    SELECT 
        c.movie_id, 
        a.name, 
        c.nr_order, 
        r.role 
    FROM 
        cast_info c 
    JOIN 
        aka_name a ON c.person_id = a.person_id 
    JOIN 
        role_type r ON c.role_id = r.id 
    WHERE 
        r.role IS NOT NULL
), MovieGenres AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS genres 
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id
), RankedMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        COUNT(ar.movie_id) AS actor_count, 
        mg.genres,
        ROW_NUMBER() OVER (PARTITION BY rm.kind_id ORDER BY rm.production_year DESC) AS rank 
    FROM 
        RecentMovies rm 
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id 
    LEFT JOIN 
        MovieGenres mg ON rm.movie_id = mg.movie_id 
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, mg.genres 
)

SELECT 
    r.movie_id, 
    r.title, 
    r.production_year, 
    r.actor_count, 
    r.genres, 
    COALESCE(r.actor_count, 0) AS total_actors, 
    CASE 
        WHEN r.actor_count IS NULL THEN 'No actors'
        ELSE 'Actors listed'
    END AS actor_status 
FROM 
    RankedMovies r 
WHERE 
    r.rank <= 5 
ORDER BY 
    r.production_year DESC, r.actor_count DESC;
