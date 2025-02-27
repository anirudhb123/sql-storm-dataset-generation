WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    LEFT JOIN aka_name a ON c.imdb_id = a.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year > 2000
    GROUP BY t.id, t.title, t.production_year, a.name
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        director_name,
        keywords,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rank
    FROM MovieDetails
)
SELECT 
    tm.title AS "Movie Title",
    tm.production_year AS "Year",
    tm.director_name AS "Director",
    STRING_AGG(kw.keyword, ', ') AS "Keywords"
FROM TopMovies tm
JOIN LATERAL UNNEST(tm.keywords) AS kw(keyword) ON true
WHERE tm.rank <= 10
GROUP BY tm.movie_id, tm.title, tm.production_year, tm.director_name
ORDER BY tm.production_year DESC;
