WITH RankedMovies AS (
    SELECT
        a.title,
        a.production_year,
        p.name AS director_name,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year) AS rank
    FROM
        aka_title a
    JOIN
        movie_companies mc ON a.id = mc.movie_id
    JOIN
        company_name c ON mc.company_id = c.id
    JOIN
        complete_cast cc ON a.id = cc.movie_id
    JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name p ON ci.person_id = p.person_id
    WHERE
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Director')
        AND a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        director_name
    FROM 
        RankedMovies
    WHERE
        rank <= 5
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(tm.director_name, 'Unknown Director') AS director_name,
    (SELECT COUNT(*) FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)) AS keyword_count,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.title AND production_year = tm.production_year LIMIT 1)) AS keywords
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.title;
