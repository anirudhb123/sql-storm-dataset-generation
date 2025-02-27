WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(c.id) AS total_cast, 
        DENSE_RANK() OVER (ORDER BY t.production_year DESC, COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id
), 
MoviesWithDetails AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.total_cast,
        (SELECT STRING_AGG(a.name, ', ') 
         FROM aka_name a 
         JOIN cast_info ci ON a.person_id = ci.person_id 
         WHERE ci.movie_id = t.id) AS cast_names,
        COALESCE(
            (SELECT COUNT(*) 
             FROM movie_company mc 
             WHERE mc.movie_id = t.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor')), 
            0
        ) AS distributor_count
    FROM 
        RankedMovies rm 
    JOIN 
        aka_title t ON rm.title = t.title AND rm.production_year = t.production_year
)
SELECT 
    m.title, 
    m.production_year, 
    m.total_cast, 
    m.cast_names, 
    m.distributor_count
FROM 
    MoviesWithDetails m
WHERE 
    m.total_cast > 5 
    AND m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.distributor_count DESC, 
    m.production_year ASC;
