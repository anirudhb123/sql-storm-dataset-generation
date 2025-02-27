WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'genre')
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mg.genres, 'No Genre') AS genres,
    ak.name AS actor_name,
    COUNT(DISTINCT cc.id) AS cast_count,
    SUM(CASE WHEN cc.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
LEFT JOIN 
    cast_info cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.person_id = ak.person_id
WHERE 
    rm.rn <= 5
GROUP BY 
    rm.title, 
    rm.production_year, 
    mg.genres, 
    ak.name
HAVING 
    COUNT(DISTINCT cc.id) > 1
ORDER BY 
    rm.production_year DESC, 
    rm.title;
