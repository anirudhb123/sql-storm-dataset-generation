WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.id) DESC) AS role_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        role_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mw.id) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mw ON tm.movie_id = mw.movie_id
    GROUP BY 
        tm.movie_id, tm.title
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_names, 'No companies') AS company_names,
    md.keyword_count,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = md.movie_id AND ci.person_role_id IS NOT NULL) AS total_roles
FROM 
    TopMovies tm
JOIN 
    MovieDetails md ON tm.movie_id = md.movie_id
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
