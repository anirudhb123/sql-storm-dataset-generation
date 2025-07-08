
WITH RankedMovies AS (
    SELECT 
        a.title,
        m.production_year,
        COUNT(c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        title m ON a.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        a.title, m.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.production_year = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.production_year = mk.movie_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_names, 'No Companies') AS companies,
    md.keyword_count
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 0 OR NOT EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = md.production_year AND mi.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Notable Film'
        )
    )
ORDER BY 
    md.production_year DESC, md.title;
