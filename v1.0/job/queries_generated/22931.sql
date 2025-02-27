WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS movie_rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
HighCastMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        has_note_count
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 3
),
MovieDetails AS (
    SELECT 
        DISTINCT mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = mt.id 
    LEFT JOIN 
        keyword ki ON ki.id = mk.keyword_id
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = mt.id)
    GROUP BY 
        mt.title, mt.production_year
),
FinalBenchmark AS (
    SELECT 
        hm.title,
        hm.production_year,
        hm.cast_count,
        hm.has_note_count,
        md.aka_names,
        md.keywords
    FROM 
        HighCastMovies hm
    JOIN 
        MovieDetails md ON hm.title = md.title AND hm.production_year = md.production_year
)
SELECT 
    title,
    production_year,
    cast_count,
    has_note_count,
    COALESCE(NULLIF(aka_names::text, '{}'), 'No Alternate Names') AS aka_names,
    COALESCE(NULLIF(keywords, ''), 'No Keywords') AS keywords,
    CASE 
        WHEN production_year < 2000 THEN 'Classic'
        WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    FinalBenchmark
WHERE 
    (cast_count > 0 AND has_note_count > 0) OR 
    (cast_count = 0 AND has_note_count IS NULL)
ORDER BY 
    production_year DESC, cast_count DESC;
