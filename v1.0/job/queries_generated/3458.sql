WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT ci.person_id) AS total_cast, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank 
    FROM 
        aka_title a 
    JOIN 
        complete_cast cc ON a.id = cc.movie_id 
    JOIN 
        cast_info ci ON cc.subject_id = ci.id 
    GROUP BY 
        a.title, a.production_year
), TopMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.total_cast 
    FROM 
        RankedMovies rm 
    WHERE 
        rm.rank <= 5
), MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords 
    FROM 
        TopMovies tm 
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id) 
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id 
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id) 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title, 
    md.production_year, 
    COALESCE(md.company_names, 'No companies') AS company_names, 
    COALESCE(md.keywords, '{}'::text[]) AS keywords 
FROM 
    MovieDetails md 
WHERE 
    md.production_year >= 2000 
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
