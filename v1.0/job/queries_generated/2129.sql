WITH MovieStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS avg_role_note,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        total_cast,
        avg_role_note,
        keywords,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, production_year DESC) AS rn
    FROM 
        MovieStats
    WHERE 
        total_cast > 0
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.keywords,
    COALESCE(pi.info, 'No additional info') AS person_info
FROM 
    TopMovies tm
LEFT JOIN 
    person_info pi ON pi.person_id = ANY(ARRAY(SELECT DISTINCT person_id FROM cast_info WHERE movie_id = tm.title_id))
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.total_cast DESC, tm.production_year DESC;
