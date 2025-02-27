WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        t.kind AS movie_type,
        COALESCE(k.keyword, 'N/A') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title) AS rank
    FROM 
        title m
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompleteMovieInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.movie_type,
        rm.keyword,
        cd.actor_name,
        cd.role_name,
        cd.actor_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    movie_type,
    keyword,
    STRING_AGG(CONCAT(actor_name, ' (', role_name, ')'), ', ' ORDER BY actor_rank) AS complete_cast
FROM 
    CompleteMovieInfo
GROUP BY 
    movie_id, title, production_year, movie_type, keyword
ORDER BY 
    production_year DESC, title;
