WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ak.name AS aka_title,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),

CastDetails AS (
    SELECT 
        c.movie_id,
        p.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_rank
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE
        c.movie_id IN (SELECT movie_id FROM RankedMovies WHERE rank = 1)
)

SELECT 
    rm.title,
    rm.production_year,
    rm.aka_title,
    cd.actor_name,
    cd.role_name
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    cd.cast_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
