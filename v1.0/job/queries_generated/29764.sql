WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS alternate_names,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000 
        AND mt.kind_id = (
            SELECT 
                id FROM kind_type 
            WHERE 
                kind = 'movie'
            LIMIT 1
        )
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
CastDetails AS (
    SELECT 
        mn.name AS main_cast_name,
        mv.movie_id,
        mv.movie_title,
        mv.production_year,
        mv.cast_count,
        mv.alternate_names
    FROM 
        RankedMovies mv
    JOIN 
        cast_info ci ON mv.movie_id = ci.movie_id
    JOIN 
        aka_name mn ON ci.person_id = mn.person_id
    WHERE 
        ci.numerator IN (1, 2)  -- Top 2 cast members
)

SELECT 
    cd.movie_title,
    cd.production_year,
    cd.cast_count,
    cd.alternate_names,
    STRING_AGG(DISTINCT cd.main_cast_name, ', ') AS main_cast_names
FROM 
    CastDetails cd
GROUP BY 
    cd.movie_title, cd.production_year, cd.cast_count, cd.alternate_names
ORDER BY 
    cd.production_year DESC, cd.cast_count DESC
LIMIT 10;
