WITH RankedMovies AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    JOIN
        complete_cast cc ON cc.movie_id = t.id
    JOIN
        cast_info c ON c.movie_id = t.id
    GROUP BY
        t.title, t.production_year
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
MovieKeywords AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT
    tm.title,
    tm.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = tm.production_year) AS info_count,
    (SELECT GROUP_CONCAT(DISTINCT p.info) FROM person_info p WHERE p.person_id IN (SELECT DISTINCT c.person_id FROM cast_info c WHERE c.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1))) AS cast_infos
FROM
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON mk.title = tm.title
ORDER BY 
    tm.production_year DESC, total_cast DESC;
