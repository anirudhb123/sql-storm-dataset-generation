
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS total_cast, 
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    cd.total_cast, 
    cd.cast_names, 
    mk.keywords,
    COALESCE(mk.keywords, 'No keywords') AS keyword_result,
    (CASE 
        WHEN cd.total_cast > 10 THEN 'Large Cast'
        WHEN cd.total_cast IS NULL THEN 'No Cast Information'
        ELSE 'Small Cast' 
    END) AS cast_size
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    (rm.rank <= 5 OR rm.production_year = 2015)
ORDER BY 
    rm.production_year DESC, rm.title;
