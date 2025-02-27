WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS year_rank
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id, 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        COUNT(mk.keyword_id) AS keyword_count,
        COALESCE(SUM(CASE WHEN mc.company_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS company_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        aka_title ak ON tm.title_id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON tm.title_id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.title_id = mc.movie_id
    GROUP BY 
        tm.title_id, tm.title, tm.production_year
)
SELECT 
    md.title_id, 
    md.title, 
    md.production_year, 
    md.aka_names, 
    md.keyword_count, 
    md.company_count
FROM 
    MovieDetails md
WHERE 
    md.keyword_count > 2
ORDER BY 
    md.production_year DESC, md.company_count DESC NULLS LAST;
