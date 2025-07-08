
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS cast_names
    FROM 
        title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        company_count, 
        cast_names
    FROM 
        MovieDetails
    WHERE 
        company_count > 0
)

SELECT 
    f.title,
    f.production_year,
    f.company_count,
    f.cast_names,
    COALESCE((
        SELECT 
            COUNT(*)
        FROM 
            movie_keyword mk
        WHERE 
            mk.movie_id = f.movie_id
    ), 0) AS keyword_count,
    CASE
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    FilteredMovies f
LEFT JOIN 
    RankedMovies r ON f.title = r.title AND f.production_year = r.production_year
WHERE 
    r.rn <= 5
ORDER BY 
    f.production_year DESC, 
    f.title ASC;
