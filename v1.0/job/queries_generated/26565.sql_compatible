
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        COUNT(DISTINCT cc.subject_id) AS cast_count,
        AVG(CAST(pi.info AS numeric)) AS avg_rating
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = mt.id
    LEFT JOIN 
        person_info pi ON pi.person_id = cc.subject_id AND pi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        aka_name ak ON ak.person_id = cc.subject_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.aka_names,
        rm.cast_count,
        rm.avg_rating
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5
        AND rm.avg_rating IS NOT NULL
        AND rm.avg_rating > 7.0
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    fm.aka_names,
    fm.cast_count,
    fm.avg_rating
FROM 
    FilteredMovies fm
ORDER BY 
    fm.avg_rating DESC, 
    fm.production_year DESC;
