WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.imdb_index,
        t.kind AS movie_kind,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_info mi ON a.id = mi.movie_id
    JOIN 
        title t ON a.id = t.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
    GROUP BY 
        a.id, a.title, a.production_year, a.imdb_index, t.kind
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        imdb_index, 
        movie_kind, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.movie_kind,
    ak.name AS actor_name,
    GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS co_actors,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keyword
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.imdb_index = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = tm.imdb_index
GROUP BY 
    tm.movie_title, tm.production_year, tm.movie_kind, ak.name, mk.keyword
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
