WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
), 
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        COALESCE(COUNT(mk.keyword), 0) AS keyword_count,
        COALESCE(STRING_AGG(DISTINCT mk.keyword, ', '), '') AS keywords,
        COALESCE(AVG(CASE WHEN pi.info_type_id = 1 THEN CAST(pi.info AS FLOAT) END), 0) AS average_rating
    FROM 
        TopMovies AS tm
    LEFT JOIN 
        movie_keyword AS mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info AS mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        person_info AS pi ON pi.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id)
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword_count,
    md.keywords,
    md.average_rating
FROM 
    MovieDetails AS md
WHERE 
    md.average_rating IS NOT NULL
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
