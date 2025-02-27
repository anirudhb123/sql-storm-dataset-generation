WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as rank,
        COUNT(mk.keyword_id) OVER (PARTITION BY a.movie_id) AS keyword_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL
), 
TopMovies AS (
    SELECT 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COUNT(ci.id) AS total_cast,
    COALESCE(CAST(STRING_AGG(DISTINCT cn.name, ', ') AS TEXT), 'No cast') AS cast_names,
    nt.kind AS title_kind
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    name cn ON ci.person_id = cn.imdb_id
LEFT JOIN 
    kind_type nt ON tm.kind_id = nt.id
GROUP BY 
    tm.title, 
    tm.production_year, 
    nt.kind
HAVING 
    COUNT(ci.id) > 0
ORDER BY 
    tm.production_year DESC, 
    total_cast DESC;
