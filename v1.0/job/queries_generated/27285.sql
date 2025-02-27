WITH RankedMovies AS (
    SELECT 
        T.title,
        T.production_year,
        C.name AS company_name,
        STRING_AGG(DISTINCT A.name, ', ') AS cast_names,
        CASE 
            WHEN COUNT(DISTINCT A.id) > 3 THEN 'Ensemble'
            WHEN COUNT(DISTINCT A.id) = 3 THEN 'Trio'
            ELSE 'Duet or Solo'
        END AS cast_size_category
    FROM 
        title T
    JOIN 
        movie_companies MC ON T.id = MC.movie_id
    JOIN 
        company_name C ON MC.company_id = C.id
    JOIN 
        cast_info CI ON T.id = CI.movie_id
    JOIN 
        aka_name A ON CI.person_id = A.person_id
    WHERE 
        T.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        T.id, T.title, T.production_year, C.name
),
HighRatedMovies AS (
    SELECT 
        RM.title,
        RM.production_year,
        RM.company_name,
        RM.cast_names,
        RM.cast_size_category,
        RANK() OVER (PARTITION BY RM.production_year ORDER BY COUNT(DISTINCT RM.cast_names) DESC) AS movie_rank
    FROM 
        RankedMovies RM
    GROUP BY 
        RM.title, RM.production_year, RM.company_name, RM.cast_names, RM.cast_size_category
)
SELECT 
    *
FROM 
    HighRatedMovies
WHERE 
    movie_rank <= 5
ORDER BY 
    production_year DESC, movie_rank;
