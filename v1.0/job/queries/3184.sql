WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count,
        COALESCE(m.company_count, 0) AS company_count
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(*) AS company_count
        FROM 
            movie_companies
        GROUP BY 
            movie_id
    ) m ON t.id = m.movie_id
    WHERE 
        t.production_year >= 2000
),
MovieStats AS (
    SELECT 
        t.movie_id,
        t.title,
        t.production_year,
        t.cast_count,
        t.company_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC, t.cast_count DESC) AS rank
    FROM 
        RankedMovies t
),
TopMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.company_count
    FROM 
        MovieStats m
    WHERE 
        m.rank <= 10
)
SELECT 
    tm.title, 
    tm.production_year,
    tm.cast_count,
    tm.company_count,
    (SELECT 
        STRING_AGG(a.name, ', ') 
     FROM 
        aka_name a 
     JOIN 
        cast_info ci ON a.person_id = ci.person_id 
     WHERE 
        ci.movie_id = tm.movie_id 
        AND a.id IS NOT NULL) AS cast_names,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = tm.movie_id 
        AND mi.note IS NOT NULL) AS info_count
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC;
