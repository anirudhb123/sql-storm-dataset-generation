
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(LENGTH(c.note)) AS avg_note_length,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY
        t.id, t.title, t.production_year
), 
top_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        avg_note_length,
        keywords,
        RANK() OVER (ORDER BY total_cast DESC, avg_note_length DESC) AS rank
    FROM
        ranked_movies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.avg_note_length,
    keyword AS keyword,
    COALESCE(a.name, 'Unknown') AS director
FROM
    top_movies tm,
    LATERAL FLATTEN(input => tm.keywords) AS keyword
LEFT JOIN
    movie_companies mc ON tm.movie_id = mc.movie_id
LEFT JOIN
    company_name a ON mc.company_id = a.imdb_id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director') 
WHERE
    tm.rank <= 10
ORDER BY
    tm.rank;
