WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie.title,
        movie.production_year,
        movie.cast_count
    FROM 
        RankedMovies movie
    WHERE 
        movie.rank_by_cast <= 5
),
MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actors,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        CASE 
            WHEN mt.production_year >= 2000 THEN 'Modern'
            ELSE 'Classic'
        END AS era
    FROM 
        TopMovies mt
    LEFT JOIN 
        cast_info ci ON mt.title = (SELECT at.title FROM aka_title at WHERE at.id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mt.title = (SELECT at.title FROM aka_title at WHERE at.id = mc.movie_id)
    GROUP BY 
        mt.title, mt.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actors, 'No Actors') AS actors,
    md.production_companies,
    md.era
FROM 
    MovieDetails md
WHERE 
    md.production_companies > 0
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
