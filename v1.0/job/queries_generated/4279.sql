WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
MoviesWithCast AS (
    SELECT 
        rm.title,
        rm.production_year,
        ci.person_role_id,
        COUNT(ci.person_id) AS cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.title = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        rm.rank <= 10
    GROUP BY 
        rm.title, rm.production_year, ci.person_role_id
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        RANK() OVER (ORDER BY cast_count DESC) AS cast_rank
    FROM 
        MoviesWithCast
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.cast_count, 0) AS cast_count,
    nt.name AS actor_name,
    ct.kind AS role_name
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)
LEFT JOIN 
    aka_name nt ON ci.person_id = nt.person_id
LEFT JOIN 
    role_type ct ON ci.role_id = ct.id
WHERE 
    tm.cast_rank <= 5
ORDER BY 
    tm.production_year DESC,
    tm.cast_count DESC;
