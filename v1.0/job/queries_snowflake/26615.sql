
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.id) DESC) AS rnk
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
        a.id, a.title, a.production_year
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        rm.keywords,
        rt.role AS movie_role
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info c ON rm.movie_id = c.movie_id
    LEFT JOIN 
        role_type rt ON c.person_role_id = rt.id
    WHERE 
        rm.rnk <= 10  
)
SELECT 
    pm.title,
    pm.production_year,
    pm.cast_count,
    pm.actors,
    pm.keywords,
    pm.movie_role
FROM 
    PopularMovies pm
ORDER BY 
    pm.cast_count DESC;
