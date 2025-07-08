
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(mo.id) AS total_movies_linked,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        movie_link mo ON a.id = mo.movie_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        kind_id, 
        cast_count, 
        total_movies_linked
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    kt.kind AS movie_kind,
    fm.cast_count,
    fm.total_movies_linked,
    LISTAGG(ak.name, ', ') AS actors
FROM 
    FilteredMovies fm
JOIN 
    cast_info c ON c.movie_id = fm.movie_id
JOIN 
    aka_name ak ON ak.person_id = c.person_id
JOIN 
    kind_type kt ON fm.kind_id = kt.id
GROUP BY 
    fm.movie_id, fm.movie_title, fm.production_year, kt.kind, fm.cast_count, fm.total_movies_linked
ORDER BY 
    fm.cast_count DESC;
