
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS role_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        role_rank <= 3
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name), 'No Companies') AS company_names,
        COALESCE(LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword), 'No Keywords') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.company_names,
    md.keywords,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year >= 2000 AND md.production_year < 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    (SELECT COUNT(DISTINCT c.person_id) 
     FROM cast_info c 
     WHERE c.movie_id = (SELECT movie_id FROM TopMovies WHERE title = md.title AND production_year = md.production_year) 
     AND c.note IS NULL) AS null_role_count
FROM 
    MovieDetails md
WHERE 
    md.keywords NOT LIKE '%trivia%'
ORDER BY 
    md.production_year DESC, md.title;
