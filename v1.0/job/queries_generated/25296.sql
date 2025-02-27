WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.imdb_index,
        k.keyword AS related_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    AND 
        a.production_year IS NOT NULL
),

ActorRoles AS (
    SELECT 
        ca.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ca.nr_order
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    JOIN 
        role_type rt ON ca.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role_name,
        COALESCE(ar.nr_order, 0) AS role_order
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.year_rank <= 5
)

SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.actor_name || ' as ' || md.role_name, ', ') AS cast_details
FROM 
    MovieDetails md
GROUP BY 
    md.title, 
    md.production_year
ORDER BY 
    md.production_year DESC, 
    md.title;
