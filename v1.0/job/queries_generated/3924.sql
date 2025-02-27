WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.title, a.production_year
),
HighCastMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS note_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    WHERE 
        rm.cast_count > 10 -- Considering movies with more than 10 cast members
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count
),
TopMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, note_count DESC) AS rank
    FROM 
        HighCastMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.note_count,
    (SELECT COUNT(DISTINCT mk.keyword)
     FROM movie_keyword mk
     JOIN aka_title at ON mk.movie_id = at.id
     WHERE at.title = tm.title) AS keyword_count,
    (SELECT STRING_AGG(DISTINCT cn.name, ', ')
     FROM complete_cast cc
     JOIN name cn ON cc.subject_id = cn.imdb_id
     WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)) AS character_names
FROM 
    TopMovies tm 
WHERE 
    tm.rank <= 10 AND 
    tm.production_year IS NOT NULL;
