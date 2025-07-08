WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        at.id, at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year >= 2000 AND rm.cast_count > 5
),
TopMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        fm.cast_count,
        RANK() OVER (ORDER BY fm.cast_count DESC) AS rank
    FROM 
        FilteredMovies fm
)
SELECT 
    tm.title, 
    tm.production_year, 
    ak.name AS main_actor,
    ct.kind AS company_type
FROM 
    TopMovies tm
JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank <= 10 AND ak.name IS NOT NULL
ORDER BY 
    tm.rank;
