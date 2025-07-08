
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY c.nr_order ASC) AS rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.title_id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON tm.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.keywords,
    COALESCE(p.info, 'No details available') AS person_info
FROM 
    MovieDetails md
LEFT JOIN 
    person_info p ON p.id = (
        SELECT 
            pi.id 
        FROM 
            person_info pi 
        JOIN 
            aka_name an ON pi.person_id = an.person_id
        WHERE 
            an.name ILIKE '%Spielberg%'
        LIMIT 1
    )
ORDER BY 
    md.production_year DESC, 
    md.title;
