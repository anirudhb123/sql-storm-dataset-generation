WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS number_of_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordMovies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        RankedMovies AS m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
FinalBenchmark AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.number_of_cast,
        rm.cast_names,
        km.keywords
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        KeywordMovies AS km ON rm.movie_id = km.movie_id
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.number_of_cast,
    fb.cast_names,
    fb.keywords
FROM 
    FinalBenchmark AS fb
WHERE 
    fb.number_of_cast > 5
ORDER BY 
    fb.production_year DESC, 
    fb.number_of_cast DESC;
