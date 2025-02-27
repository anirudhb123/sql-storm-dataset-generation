WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COALESCE(mc.note, 'No Company Info') AS company_note
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id IN (
            SELECT m.id 
            FROM aka_title m 
            WHERE m.title = tm.title AND m.production_year = tm.production_year
        )
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id IN (
            SELECT m.id 
            FROM aka_title m 
            WHERE m.title = tm.title AND m.production_year = tm.production_year
        )
    GROUP BY 
        tm.title, tm.production_year, mc.note
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.company_note,
    CASE 
        WHEN md.production_year IS NULL THEN 'Year Unknown' 
        ELSE 'Year Known'
    END AS year_status,
    STRING_AGG(DISTINCT ca.note, '; ' ORDER BY ca.person_role_id) AS role_notes
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON mc.movie_id IN (
        SELECT m.id 
        FROM aka_title m 
        WHERE m.title = md.title AND m.production_year = md.production_year
    )
LEFT JOIN 
    complete_cast cc ON cc.movie_id IN (
        SELECT m.id 
        FROM aka_title m 
        WHERE m.title = md.title AND m.production_year = md.production_year
    )
LEFT JOIN 
    cast_info ca ON ca.movie_id = cc.movie_id
GROUP BY 
    md.title, md.production_year, md.company_note
HAVING 
    COUNT(DISTINCT ca.id) >= 2
ORDER BY 
    md.production_year DESC, 
    md.title;
