
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(dc.id) AS direct_cast_count,
        COUNT(mc.id) AS movie_company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(dc.id) DESC) AS ranking
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info dc ON t.id = dc.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        direct_cast_count,
        movie_company_count
    FROM 
        RankedMovies
    WHERE 
        ranking <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT c.role_id) AS roles
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info c ON tm.title = (SELECT title FROM aka_title WHERE id = c.movie_id LIMIT 1)
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.aka_names,
    md.roles,
    COALESCE(COUNT(mk.id), 0) AS keyword_count
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.title = (SELECT title FROM aka_title WHERE id = mk.movie_id LIMIT 1)
GROUP BY 
    md.title, md.production_year, md.aka_names, md.roles
ORDER BY 
    md.production_year DESC, md.title;
