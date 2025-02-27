WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastDetails AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        r.role AS role_name,
        COUNT(c.id) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS movie_details
    FROM 
        movie_info m
    JOIN 
        movie_info_idx mi ON m.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%rating%')
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.role_name,
    mi.movie_details
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank_year = 1
ORDER BY 
    rm.production_year DESC, cd.total_roles DESC, rm.title;
