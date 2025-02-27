WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_note_present,
        STRING_AGG(DISTINCT cn.name, ', ') AS character_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        char_name cn ON cc.subject_id = cn.id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
    HAVING 
        COUNT(cc.subject_id) > 5
),
FinalSelection AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.avg_note_present,
        md.character_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    WHERE 
        md.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        md.movie_id, md.title, md.production_year, md.avg_note_present, md.character_names
)
SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.avg_note_present,
    fs.character_names,
    COALESCE(fs.keyword_count, 0) AS keyword_count
FROM 
    FinalSelection fs
ORDER BY 
    fs.production_year DESC, fs.keyword_count DESC NULLS LAST;
