WITH 
    RankedMovies AS (
        SELECT 
            a.id AS movie_id,
            a.title,
            a.production_year,
            a.kind_id,
            COUNT(DISTINCT ca.person_id) AS cast_count,
            STRING_AGG(DISTINCT ak.name, ', ') AS actors,
            STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
        FROM 
            aka_title a
        JOIN 
            complete_cast cc ON a.id = cc.movie_id
        JOIN 
            cast_info ca ON cc.subject_id = ca.id
        JOIN 
            aka_name ak ON ca.person_id = ak.person_id
        LEFT JOIN 
            movie_keyword mk ON a.id = mk.movie_id
        LEFT JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            a.id, a.title, a.production_year, a.kind_id
    ),
    MovieDetails AS (
        SELECT 
            rm.movie_id,
            rm.title,
            rm.production_year,
            rm.cast_count,
            rm.actors,
            CASE 
                WHEN rm.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series')) THEN 'Feature/Series'
                ELSE 'Other'
            END AS film_type
        FROM 
            RankedMovies rm
    )
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actors,
    md.film_type
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 50;
