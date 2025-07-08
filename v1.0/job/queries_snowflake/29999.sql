
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
PopularMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year >= 2000
)
SELECT 
    pm.movie_id,
    pm.movie_title,
    pm.production_year,
    pm.total_cast,
    pm.cast_names,
    pm.rank,
    kt.kind AS movie_kind
FROM 
    PopularMovies pm
JOIN 
    kind_type kt ON pm.kind_id = kt.id
WHERE 
    pm.rank <= 10
ORDER BY 
    pm.rank;
