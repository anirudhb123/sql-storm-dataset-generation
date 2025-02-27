WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aka_names
    FROM 
        RankedMovies AS rm
    WHERE 
        rm.year_rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    GROUP_CONCAT(DISTINCT ci.note) AS notes
FROM 
    TopMovies AS tm
JOIN 
    complete_cast AS cc ON tm.movie_id = cc.movie_id
JOIN 
    movie_info AS mi ON cc.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword AS mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Awards', 'Nominations'))
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count, tm.aka_names
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
