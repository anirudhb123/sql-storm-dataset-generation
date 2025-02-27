WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN aka_name ak ON ak.person_id = ci.person_id
    GROUP BY mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        RANK() OVER (ORDER BY md.cast_count DESC) AS rank
    FROM MovieDetails md
    WHERE md.production_year >= 2000
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    COALESCE((SELECT COUNT(DISTINCT mc.company_id) 
               FROM movie_companies mc 
               WHERE mc.movie_id = tm.movie_id), 0) AS company_count,
    CASE 
        WHEN tm.cast_count > 5 THEN 'Large Cast'
        WHEN tm.cast_count BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size_category,
    tm.aka_names
FROM TopMovies tm
WHERE tm.rank <= 10
ORDER BY tm.cast_count DESC, tm.title;
