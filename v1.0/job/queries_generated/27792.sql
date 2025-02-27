WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC, COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.production_year IS NOT NULL
    GROUP BY
        m.id, m.title, m.production_year
),
SelectedMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        cast_count,
        actors,
        keywords
    FROM
        RankedMovies
    WHERE
        rank <= 10
)
SELECT
    sm.title,
    sm.production_year,
    sm.cast_count,
    sm.actors,
    sm.keywords,
    CASE 
        WHEN sm.cast_count > 5 THEN 'Popular'
        ELSE 'Niche'
    END AS movie_category
FROM
    SelectedMovies sm
ORDER BY
    sm.production_year DESC, sm.cast_count DESC;
