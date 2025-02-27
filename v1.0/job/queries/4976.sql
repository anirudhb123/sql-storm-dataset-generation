WITH MovieRankings AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, production_year, total_cast
    FROM 
        MovieRankings
    WHERE 
        rank <= 10
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CompleteMovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.total_cast,
        COALESCE(cd.company_names, 'No Company Information') AS company_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        CompanyDetails cd ON tm.title = (SELECT title FROM aka_title WHERE id = cd.movie_id)
)
SELECT 
    cmd.title,
    cmd.production_year,
    cmd.total_cast,
    cmd.company_info,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = (SELECT id FROM aka_title WHERE title = cmd.title LIMIT 1)) AS info_count,
    CASE
        WHEN EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = cmd.title LIMIT 1)) THEN 'Has Keywords'
        ELSE 'No Keywords'
    END AS keyword_status
FROM 
    CompleteMovieDetails cmd
ORDER BY 
    cmd.production_year DESC, cmd.total_cast DESC;
