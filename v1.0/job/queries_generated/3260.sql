WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_per_year <= 5
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role)) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cd.total_cast, 0) AS total_cast_members,
    cd.cast_names,
    k.keyword AS associated_keyword
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.title = cd.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    tm.production_year > 2000
ORDER BY 
    tm.production_year DESC, 
    total_cast_members DESC, 
    tm.title ASC;
