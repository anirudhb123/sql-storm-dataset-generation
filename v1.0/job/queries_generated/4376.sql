WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank
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
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        MAX(i.info) AS info_data
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON tm.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info mi ON tm.id = mi.movie_id
    LEFT JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.keywords, 'No keywords') AS keywords,
    COALESCE(md.companies, 'No companies') AS companies,
    COALESCE(md.info_data, 'No additional info') AS info_data
FROM 
    MovieDetails md
LEFT JOIN 
    aka_name an ON md.title ILIKE '%' || an.name || '%'
WHERE 
    an.name IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
