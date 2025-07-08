
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS ranking
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        ranking <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    LISTAGG(DISTINCT ki.keyword, ', ') WITHIN GROUP (ORDER BY ki.keyword) AS keywords,
    LISTAGG(DISTINCT mt.info, ', ') WITHIN GROUP (ORDER BY mt.info) AS movie_info,
    t.kind AS movie_kind
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    movie_info_idx mt ON tm.movie_id = mt.movie_id AND mi.info_type_id = mt.info_type_id
LEFT JOIN 
    kind_type t ON mt.info_type_id = t.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.total_cast, tm.cast_names, t.kind
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
