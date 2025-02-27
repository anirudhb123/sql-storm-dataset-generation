WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS avg_role_order
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        total_cast, 
        avg_role_order,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY total_cast DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.avg_role_order,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     WHERE mc.movie_id = tm.movie_id) AS company_count,
    CASE 
        WHEN tm.total_cast > 10 THEN 'Large Cast'
        WHEN tm.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast' 
    END AS cast_size_category
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 5
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
