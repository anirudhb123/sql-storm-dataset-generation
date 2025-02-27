WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info cc ON at.id = cc.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
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
        COALESCE(GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name), 'No Cast') AS cast_names,
        COALESCE(GROUP_CONCAT(DISTINCT mn.name ORDER BY mn.name), 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
    LEFT JOIN 
        keyword mn ON mk.keyword_id = mn.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_names,
    md.keywords,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
GROUP BY 
    md.title, md.production_year, md.cast_names, md.keywords
ORDER BY 
    md.production_year DESC, company_count DESC;
