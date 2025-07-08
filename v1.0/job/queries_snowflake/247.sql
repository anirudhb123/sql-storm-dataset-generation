
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id
),

MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mi.info, 'No info available') AS movie_info,
        COALESCE(ki.keyword, 'No keywords') AS movie_keyword
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
    LEFT JOIN 
        movie_keyword ma ON m.id = ma.movie_id
    LEFT JOIN 
        keyword ki ON ma.keyword_id = ki.id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.total_cast,
    cd.cast_names,
    mi.movie_info,
    mi.movie_keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, cd.total_cast DESC;
