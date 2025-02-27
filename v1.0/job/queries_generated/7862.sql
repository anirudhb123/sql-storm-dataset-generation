WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_cast_with_note
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        total_cast,
        avg_cast_with_note,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, avg_cast_with_note DESC) AS rn
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.avg_cast_with_note,
    c.name AS company_name,
    co.kind AS company_type
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type co ON mc.company_type_id = co.id
WHERE 
    tm.rn <= 10 
ORDER BY 
    tm.total_cast DESC, 
    tm.avg_cast_with_note DESC;
