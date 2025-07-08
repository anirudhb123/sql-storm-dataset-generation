
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        LISTAGG(DISTINCT rm.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank = 1
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
CastDetails AS (
    SELECT 
        c.movie_id,
        LISTAGG(DISTINCT CONCAT(p.name, ' as ', rt.role), ', ') AS cast
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cd.cast, 'No cast information available') AS cast_info,
    tm.keywords
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
ORDER BY 
    tm.production_year DESC;
