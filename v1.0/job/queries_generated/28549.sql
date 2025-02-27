WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),

CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),

MovieInfo AS (
    SELECT 
        m.movie_id,
        MIN(m.info) AS synopsis,
        COUNT(DISTINCT ki.keyword) AS keyword_count
    FROM 
        movie_info m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        m.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.total_cast,
    cd.cast_names,
    mi.synopsis,
    mi.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
