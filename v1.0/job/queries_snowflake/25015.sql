
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        LISTAGG(DISTINCT an.name, ', ') WITHIN GROUP (ORDER BY an.name) AS actors
    FROM 
        aka_title a
    JOIN 
        cast_info ca ON a.id = ca.movie_id
    JOIN 
        aka_name an ON ca.person_id = an.person_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
MovieStatistics AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        cast_count,
        actors,
        DENSE_RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_by_cast
    FROM 
        RankedMovies
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    m.actors,
    kt.kind AS kind_title,
    ct.kind AS company_type
FROM 
    MovieStatistics m
JOIN 
    kind_type kt ON m.kind_id = kt.id
JOIN 
    movie_companies mc ON mc.movie_id = m.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    m.rank_by_cast <= 10
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
