WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(mc.company_id) AS company_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS avg_cast_note,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title a 
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        a.title, a.production_year
), NullFilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        company_count, 
        avg_cast_note
    FROM 
        RankedMovies
    WHERE 
        avg_cast_note IS NOT NULL
)

SELECT 
    n.name, 
    nm.gender, 
    m.title,
    m.production_year,
    m.company_count,
    COALESCE(NULLIF(m.avg_cast_note, 0), 'No Notes Available') AS avg_notes_status
FROM 
    NullFilteredMovies m
INNER JOIN 
    complete_cast cc ON m.title = cc.movie_id
INNER JOIN 
    aka_name n ON cc.subject_id = n.person_id
LEFT JOIN 
    name nm ON nm.id = n.id
WHERE 
    m.production_year > 2000
ORDER BY 
    m.company_count DESC, 
    m.production_year DESC
LIMIT 100;
