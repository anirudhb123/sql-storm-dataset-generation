WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_count_rank <= 5
),
CompanyMovieInfo AS (
    SELECT 
        m.movie_id,
        string_agg(DISTINCT c.name, ', ') AS company_names,
        COUNT(DISTINCT ci.id) AS total_companies
    FROM 
        movie_companies mci
    JOIN 
        company_name c ON mci.company_id = c.id
    JOIN 
        complete_cast cc ON mci.movie_id = cc.movie_id
    JOIN 
        title m ON m.id = mci.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget')
    LEFT JOIN 
        movie_info_idx mii ON mi.movie_id = mii.movie_id
    WHERE 
        bs_upper(mi.info) IS NULL OR mii.info IS NOT NULL
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.movie_title,
    tm.production_year,
    cmi.company_names,
    cmi.total_companies
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyMovieInfo cmi ON tm.movie_title = (SELECT title FROM title WHERE imdb_id = (SELECT DISTINCT movie_id FROM aka_title WHERE title = tm.movie_title)
)
ORDER BY 
    tm.production_year DESC, tm.movie_title;
