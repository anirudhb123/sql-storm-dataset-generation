
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
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
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT ki.keyword, ', ') WITHIN GROUP (ORDER BY ki.keyword) AS keywords,
        COUNT(mi.id) AS info_count
    FROM 
        movie_info mi
    LEFT JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast,
    cd.cast_names,
    COALESCE(mi.keywords, 'No Keywords') AS keywords,
    mi.info_count,
    rm.rank_per_year
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.production_year >= 2000
AND 
    (mi.keywords IS NULL OR mi.info_count > 1)
ORDER BY 
    rm.production_year DESC, 
    rm.rank_per_year,
    total_cast DESC;
