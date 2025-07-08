
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
CastDetails AS (
    SELECT 
        ca.movie_id,
        LISTAGG(DISTINCT CONCAT(a.name, ' (', rt.role, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS cast_info
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    JOIN 
        role_type rt ON ca.role_id = rt.id
    GROUP BY 
        ca.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_count,
    cd.cast_info
FROM 
    TopMovies tm
LEFT JOIN 
    CastDetails cd ON tm.movie_id = cd.movie_id
ORDER BY 
    tm.production_year DESC, tm.company_count DESC;
