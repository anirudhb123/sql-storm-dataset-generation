WITH MovieDetails AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        cast_names,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        MovieDetails
),
HighCastMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        cast_names
    FROM 
        TopMovies
    WHERE 
        total_cast >= (SELECT AVG(total_cast) FROM TopMovies)
)
SELECT 
    hcm.movie_title,
    hcm.production_year,
    hcm.total_cast,
    COALESCE(NULLIF(hcm.cast_names, ''), 'No cast available') AS cast_names,
    (SELECT STRING_AGG(DISTINCT ci.note, ', ') 
     FROM cast_info ci 
     JOIN complete_cast cc ON ci.id = cc.subject_id 
     WHERE cc.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = hcm.movie_title LIMIT 1)) AS casting_notes
FROM 
    HighCastMovies hcm
ORDER BY 
    hcm.production_year DESC, hcm.total_cast DESC
LIMIT 10;
