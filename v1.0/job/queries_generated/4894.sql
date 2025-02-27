WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title, 
        mt.production_year, 
        COUNT(ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
),
MovieInfoWithKeywords AS (
    SELECT 
        tm.movie_title, 
        tm.production_year, 
        GROUP_CONCAT(mk.keyword) AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.movie_title = (SELECT title FROM aka_title WHERE id = mk.movie_id) 
    GROUP BY 
        tm.movie_title, tm.production_year
)
SELECT 
    mw.movie_title,
    mw.production_year,
    mw.keywords,
    ARRAY(SELECT c.kind 
          FROM movie_companies mc 
          JOIN company_type c ON mc.company_type_id = c.id 
          WHERE mc.movie_id = (SELECT id FROM aka_title WHERE title = mw.movie_title LIMIT 1)) AS companies,
    (SELECT COUNT(DISTINCT person_id) 
     FROM person_info pi 
     WHERE pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'bio') 
     AND pi.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = mw.movie_title LIMIT 1))) AS bio_actors_count
FROM 
    MovieInfoWithKeywords mw
WHERE 
    mw.keywords IS NOT NULL
ORDER BY 
    mw.production_year DESC, 
    mw.movie_title ASC;
