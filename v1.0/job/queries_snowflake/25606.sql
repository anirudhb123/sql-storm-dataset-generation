
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names,
        rank_within_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aka_names,
    mi.info AS movie_info,
    rt.role AS leading_role
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id
LEFT JOIN 
    role_type rt ON rt.id = (SELECT ci.person_role_id FROM cast_info ci WHERE ci.movie_id = tm.movie_id LIMIT 1)
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office' LIMIT 1)
ORDER BY 
    tm.production_year, tm.cast_count DESC;
