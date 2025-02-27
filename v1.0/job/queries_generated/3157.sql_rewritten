WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        COUNT(CI.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY T.production_year ORDER BY COUNT(CI.person_id) DESC) AS rn
    FROM 
        title T
    LEFT JOIN 
        cast_info CI ON T.id = CI.movie_id
    GROUP BY 
        T.id, T.title, T.production_year
),
Directors AS (
    SELECT 
        CI.movie_id,
        A.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY CI.movie_id ORDER BY CI.nr_order) AS dir_order
    FROM 
        cast_info CI
    JOIN 
        aka_name A ON CI.person_id = A.person_id
    WHERE 
        CI.role_id = (SELECT id FROM role_type WHERE role = 'director')
),
MoviesWithDirectors AS (
    SELECT 
        RM.movie_id,
        RM.title,
        RM.production_year,
        RM.cast_count,
        D.director_name
    FROM 
        RankedMovies RM
    LEFT JOIN 
        Directors D ON RM.movie_id = D.movie_id AND D.dir_order = 1
)

SELECT 
    M.title,
    M.production_year,
    COALESCE(M.cast_count, 0) AS total_cast,
    COALESCE(M.director_name, 'Unknown') AS main_director
FROM 
    MoviesWithDirectors M
WHERE 
    M.production_year >= 2000
    AND M.cast_count > 5
ORDER BY 
    M.production_year DESC, 
    M.cast_count DESC
LIMIT 50;