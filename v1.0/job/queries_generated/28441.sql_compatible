
WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ARRAY_AGG(DISTINCT c.role_id) AS role_ids,
        COUNT(DISTINCT m.company_id) AS company_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id AND c.movie_id = a.id
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    WHERE 
        a.production_year >= 2000 
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        a.id, a.title, a.production_year
),

TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        role_ids, 
        company_count,
        ROW_NUMBER() OVER (ORDER BY company_count DESC) AS rank
    FROM 
        MovieDetails
)

SELECT 
    tm.title,
    tm.production_year,
    ARRAY_AGG(DISTINCT ak.name) AS aka_names,
    ARRAY_AGG(DISTINCT p.info) AS person_info 
FROM 
    TopMovies tm
LEFT JOIN 
    aka_name ak ON ak.person_id IN (SELECT UNNEST(tm.role_ids))
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.rank
ORDER BY 
    tm.rank;
