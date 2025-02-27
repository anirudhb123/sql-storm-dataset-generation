WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY a.id) AS total_cast,
        RANK() OVER (ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
        AND a.production_year >= 2000
),
HighCastMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        total_cast > (
            SELECT AVG(total_cast) FROM RankedMovies
        )
)
SELECT 
    h.title,
    h.production_year,
    COALESCE(ci.note, 'No additional info') AS cast_info,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved
FROM 
    HighCastMovies h
LEFT JOIN 
    complete_cast cc ON h.title = (SELECT title FROM aka_title WHERE id = cc.movie_id)
LEFT JOIN 
    movie_companies mc ON cc.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON h.production_year = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
GROUP BY 
    h.title, h.production_year, ci.note
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    h.production_year DESC, h.title;
