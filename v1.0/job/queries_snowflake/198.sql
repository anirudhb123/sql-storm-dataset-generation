
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
    COALESCE(SUM(CAST(mi.info AS FLOAT)), 0) AS total_box_office,
    CASE 
        WHEN COUNT(DISTINCT mc.company_id) > 0 THEN 'Yes' 
        ELSE 'No' 
    END AS has_movie_company
FROM 
    TopMovies tm
LEFT JOIN 
    cast_info c ON tm.movie_title = (SELECT title FROM aka_title WHERE id = c.movie_id)
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON c.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
GROUP BY 
    tm.movie_title, tm.production_year, tm.total_cast
ORDER BY 
    tm.production_year DESC, tm.total_cast DESC;
