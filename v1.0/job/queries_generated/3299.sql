WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS has_note_ratio
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info = 'rating'
    AND 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        has_note_ratio,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, production_year DESC) AS rn
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cn.name, 'Unknown') AS company_name,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    tm.cast_count,
    tm.has_note_ratio
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.imdb_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.rn <= 10
    AND (tm.cast_count > 0 OR tm.has_note_ratio IS NOT NULL)
ORDER BY 
    tm.cast_count DESC, 
    tm.production_year DESC;
