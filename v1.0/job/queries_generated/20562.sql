WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
MovieCompanies AS (
    SELECT 
        m.title,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(m.note, 'No note provided') AS note,
        m.production_year
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    mc.company_name,
    mc.company_type,
    CASE 
        WHEN mc.note IS NULL THEN 'No additional information'
        ELSE mc.note 
    END AS company_note,
    NULLIF(mc.note, 'No note provided') AS cleaned_note,
    COALESCE(k.keyword, 'No keyword') AS movie_keyword
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCompanies mc ON tm.title = mc.title AND tm.production_year = mc.production_year
LEFT JOIN 
    movie_keyword mk ON mc.title = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    COALESCE(mc.company_type, 'Unknown') <> 'Unknown'
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
