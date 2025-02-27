
WITH RankedMovies AS (
    SELECT 
        T.id AS movie_id,
        T.title,
        T.production_year,
        RANK() OVER (PARTITION BY T.production_year ORDER BY COUNT(CI.id) DESC) AS rank_by_cast
    FROM 
        aka_title T
    LEFT JOIN 
        movie_companies MC ON T.id = MC.movie_id
    LEFT JOIN 
        cast_info CI ON T.id = CI.movie_id
    GROUP BY 
        T.id, T.title, T.production_year
), MovieInfo AS (
    SELECT 
        M.movie_id,
        COALESCE(MI.info, 'No Info Available') AS additional_info
    FROM 
        RankedMovies M
    LEFT JOIN 
        movie_info MI ON M.movie_id = MI.movie_id 
    WHERE 
        MI.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot' LIMIT 1)
), FilteredMovies AS (
    SELECT 
        RM.*,
        MI.additional_info
    FROM 
        RankedMovies RM
    LEFT JOIN 
        MovieInfo MI ON RM.movie_id = MI.movie_id
    WHERE 
        RM.rank_by_cast <= 5
)
SELECT 
    FM.title,
    FM.production_year,
    COALESCE(GROUP_CONCAT(A.name), 'No Cast') AS cast_names,
    FM.additional_info
FROM 
    FilteredMovies FM
LEFT JOIN 
    cast_info CI ON FM.movie_id = CI.movie_id
LEFT JOIN 
    aka_name A ON CI.person_id = A.person_id
GROUP BY 
    FM.movie_id, FM.title, FM.production_year, FM.additional_info
ORDER BY 
    FM.production_year DESC, FM.title;
