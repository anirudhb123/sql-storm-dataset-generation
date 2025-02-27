WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(CONCAT(a.name, ' (', r.role, ')'), ', ') AS cast_list
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mi.info END) AS budget,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating') THEN mi.info END) AS rating
    FROM 
        movie_info mi
    JOIN 
        title m ON mi.movie_id = m.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.actor_count,
    cd.cast_list,
    COALESCE(mi.budget, 'Unknown') AS budget,
    COALESCE(mi.rating, 'Not Rated') AS rating
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, cd.actor_count DESC;
