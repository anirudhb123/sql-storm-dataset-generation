
WITH FilmDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast c ON t.id = c.movie_id
    LEFT JOIN 
        cast_info cc ON c.subject_id = cc.id
    LEFT JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    GROUP BY 
        t.title, t.production_year
),
YearlyProduction AS (
    SELECT 
        production_year, 
        COUNT(*) AS films_produced
    FROM 
        aka_title
    GROUP BY 
        production_year
)
SELECT 
    fd.movie_title,
    fd.production_year,
    fd.total_cast,
    fd.actor_names,
    yp.films_produced,
    CASE 
        WHEN yp.films_produced > 5 THEN 'High Output'
        WHEN yp.films_produced BETWEEN 3 AND 5 THEN 'Moderate Output'
        ELSE 'Low Output' 
    END AS production_category
FROM 
    FilmDetails fd
JOIN 
    YearlyProduction yp ON fd.production_year = yp.production_year
WHERE 
    fd.production_year >= 2000
ORDER BY 
    fd.production_year DESC, 
    fd.total_cast DESC
LIMIT 50;
