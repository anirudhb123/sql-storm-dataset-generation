WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT
        mt.movie_id,
        GROUP_CONCAT(DISTINCT kt.keyword ORDER BY kt.keyword) AS genres
    FROM
        movie_keyword mk
    JOIN
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY
        mt.movie_id
)
SELECT
    a.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year,
    mg.genres,
    COALESCE(rt.role, 'Unknown') AS role,
    CASE
        WHEN mv.production_year < 2000 THEN 'Classic'
        WHEN mv.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_era,
    COUNT(DISTINCT c.person_id) FILTER (WHERE c.note IS NOT NULL) AS non_empty_cast_count,
    SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS null_note_count
FROM
    cast_info c
JOIN
    aka_name a ON c.person_id = a.person_id
JOIN
    RankedMovies mv ON c.movie_id = mv.movie_id
LEFT JOIN
    MovieGenres mg ON mv.movie_id = mg.movie_id
LEFT JOIN
    role_type rt ON c.role_id = rt.id
WHERE
    mv.rank <= 5
    AND (a.name IS NOT NULL OR a.name != '')
    AND (mv.production_year IS NOT NULL OR mv.production_year > 1990) 
    AND NOT EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = mv.movie_id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Disputed')
        AND mi.info LIKE '%blockbuster%'
    )
GROUP BY
    a.name, mv.title, mv.production_year, mg.genres, rt.role
ORDER BY
    mv.production_year DESC, a.name;
