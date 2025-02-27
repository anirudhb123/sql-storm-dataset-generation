WITH MovieDetails AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_note_flag
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        mt.production_year > 2000
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast,
        has_note_flag,
        RANK() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank
    FROM 
        MovieDetails
),
MovieKeywords AS (
    SELECT 
        mt.id AS movie_id,
        GROUP_CONCAT(mk.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id
)
SELECT 
    TM.title,
    TM.production_year,
    TM.total_cast,
    TM.has_note_flag,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN TM.total_cast > 10 THEN 'Large Cast'
        WHEN TM.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    STRING_AGG(DISTINCT ci.note, ', ') AS cast_notes
FROM 
    TopMovies TM
LEFT JOIN 
    MovieKeywords mk ON TM.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id IN (SELECT movie_id FROM complete_cast WHERE subject_id = ci.person_id)
WHERE 
    TM.rank <= 10
GROUP BY 
    TM.title, TM.production_year, TM.total_cast, TM.has_note_flag, mk.keywords
ORDER BY 
    TM.production_year DESC, TM.total_cast DESC;
