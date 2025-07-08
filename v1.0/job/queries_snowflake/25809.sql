
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        m.kind_id,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id, m.title, m.production_year, m.kind_id
),
TopGenres AS (
    SELECT 
        k.keyword AS genre,
        COUNT(m.movie_id) AS genre_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        RankedMovies m ON mk.movie_id = m.movie_id
    GROUP BY
        k.keyword
    ORDER BY
        genre_count DESC
    LIMIT 5
),
MovieDetails AS (
    SELECT
        r.title,
        r.production_year,
        r.cast_count,
        p.name AS director,
        g.genre
    FROM
        RankedMovies r
    JOIN
        movie_companies mc ON r.movie_id = mc.movie_id
    JOIN
        company_name p ON mc.company_id = p.imdb_id
    JOIN
        TopGenres g ON r.kind_id IN (SELECT id FROM kind_type WHERE kind = g.genre)
    WHERE
        mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
)
SELECT 
    CONCAT(m.title, ' (', m.production_year, ') - Directed by: ', m.director, ' - Genre: ', m.genre) AS movie_info,
    m.cast_count
FROM
    MovieDetails m
WHERE
    m.cast_count > 10
ORDER BY
    m.production_year DESC, m.cast_count DESC;
