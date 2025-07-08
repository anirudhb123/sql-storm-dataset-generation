
WITH MovieData AS (
    SELECT 
        a.title,
        a.production_year,
        cnt.cast_count,
        COALESCE(kw.keyword_list, 'No Keywords') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN (
        SELECT 
            movie_id, 
            COUNT(DISTINCT person_id) AS cast_count
        FROM 
            cast_info 
        GROUP BY movie_id
    ) cnt ON a.id = cnt.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id, 
            LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) kw ON a.id = kw.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2020
),
TopMovies AS (
    SELECT 
        MD.title,
        MD.production_year,
        MD.cast_count,
        MD.keywords,
        MD.year_rank
    FROM 
        MovieData MD
    WHERE 
        MD.year_rank <= 3
)
SELECT 
    TM.title,
    TM.production_year,
    TM.cast_count,
    TM.keywords
FROM 
    TopMovies TM
WHERE 
    TM.cast_count IS NOT NULL
ORDER BY 
    TM.production_year DESC, TM.cast_count DESC;
