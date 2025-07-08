
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS all_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.kind_id = 1 AND 
        t.production_year > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
MostActorsMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.all_actors
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_count,
    m.all_actors,
    c.name AS company_name,
    i.info AS additional_info
FROM 
    MostActorsMovies m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    info_type i ON mi.info_type_id = i.id
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
