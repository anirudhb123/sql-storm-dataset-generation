
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS alias_names
    FROM 
        title t
    JOIN 
        aka_title at ON at.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.alias_names,
        RANK() OVER (ORDER BY rm.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tr.movie_title,
    tr.production_year,
    tr.cast_count,
    tr.alias_names,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = t.id) AS info_count
FROM 
    TopRatedMovies tr
JOIN 
    title t ON t.title = tr.movie_title
WHERE 
    tr.rank <= 10
ORDER BY 
    tr.rank;
