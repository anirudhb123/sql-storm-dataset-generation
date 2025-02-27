WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(cc.movie_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast
    FROM 
        MovieDetails
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    r.role AS role_description,
    ct.kind AS company_type
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON tm.title = ci.movie_id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
LEFT JOIN 
    movie_companies mc ON tm.title = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank_by_cast <= 5
    AND ct.kind IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
