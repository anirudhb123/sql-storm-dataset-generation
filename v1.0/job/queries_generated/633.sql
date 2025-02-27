WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rn
    FROM
        aka_title a
    LEFT JOIN
        cast_info ca ON a.id = ca.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        mo.info,
        COALESCE(cn.name, 'Unknown Company') AS company_name
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mo ON tm.title = mo.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.title
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
)
SELECT 
    md.title,
    md.production_year,
    md.info,
    md.company_name,
    CASE 
        WHEN md.info IS NULL THEN 'No Info Available'
        ELSE md.info
    END AS info_status
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
    AND md.company_name IS NOT NULL
UNION ALL
SELECT 
    'Aggregate Info' AS title,
    NULL AS production_year,
    COUNT(*) AS total_movies,
    NULL AS company_name,
    NULL AS info_status
FROM 
    MovieDetails
WHERE 
    company_name IS NOT NULL;
