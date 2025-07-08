
WITH YearlyMovieStats AS (
    SELECT 
        t.production_year,
        COUNT(DISTINCT t.id) AS total_movies,
        AVG(LENGTH(t.title)) AS avg_title_length,
        COUNT(DISTINCT tc.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info tc ON cc.subject_id = tc.person_id
    GROUP BY 
        t.production_year
),
TopDirectors AS (
    SELECT 
        c.name,
        COUNT(DISTINCT mc.movie_id) AS directed_movies
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Director')
    GROUP BY 
        c.name
    HAVING 
        COUNT(DISTINCT mc.movie_id) > 5
)
SELECT 
    yms.production_year,
    yms.total_movies,
    yms.avg_title_length,
    COALESCE(td.directed_movies, 0) AS total_directors,
    CASE 
        WHEN yms.total_movies > 0 THEN (CAST(yms.total_cast AS FLOAT) / yms.total_movies) 
        ELSE NULL 
    END AS avg_cast_per_movie
FROM 
    YearlyMovieStats yms
LEFT JOIN 
    TopDirectors td ON yms.production_year = td.directed_movies
ORDER BY 
    yms.production_year DESC
LIMIT 10;
