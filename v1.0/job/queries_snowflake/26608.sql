
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS director_name,
        k.keyword AS movie_keyword,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    JOIN 
        movie_info mi ON a.id = mi.movie_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name c ON ci.person_id = c.person_id
    WHERE 
        a.production_year IS NOT NULL AND 
        k.keyword IS NOT NULL
), FilteredMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.director_name,
        rm.movie_keyword
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank <= 5
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.director_name,
    LISTAGG(fm.movie_keyword, ', ') WITHIN GROUP (ORDER BY fm.movie_keyword) AS keywords
FROM 
    FilteredMovies fm
GROUP BY 
    fm.movie_title, 
    fm.production_year, 
    fm.director_name
ORDER BY 
    fm.production_year DESC;
