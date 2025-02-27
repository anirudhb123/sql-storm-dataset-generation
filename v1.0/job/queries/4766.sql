WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
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
        rank_per_year <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    ak.name AS actor_name,
    ak.imdb_index AS actor_imdb_index,
    COALESCE(mt.info, 'N/A') AS movie_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mt ON tm.movie_id = mt.movie_id AND mt.info_type_id = (SELECT id FROM info_type WHERE info = 'Summary')
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, ak.name, ak.imdb_index, mt.info
HAVING 
    COUNT(DISTINCT ak.id) > 0 
ORDER BY 
    tm.production_year DESC, tm.title;
