WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastingRoles AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_cast_present
    FROM
        cast_info c
    JOIN
        name p ON c.person_id = p.id
    GROUP BY
        c.movie_id
),
MovieDetails AS (
    SELECT
        m.movie_id,
        m.title,
        COALESCE(cr.total_cast, 0) AS total_cast,
        COALESCE(cr.female_cast_present, 0) AS female_present,
        CASE 
            WHEN cr.total_cast > 5 THEN 'Large' 
            WHEN cr.total_cast BETWEEN 3 AND 5 THEN 'Medium' 
            ELSE 'Small' 
        END AS cast_size
    FROM
        RankedMovies m
    LEFT JOIN
        CastingRoles cr ON m.movie_id = cr.movie_id
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.female_present,
    md.cast_size,
    CASE
        WHEN md.female_present = 1 AND md.total_cast > 0 THEN 'Diverse Cast'
        WHEN md.female_present = 0 AND md.total_cast > 0 THEN 'All Male Cast'
        ELSE 'No Cast'
    END AS cast_diversity,
    EXISTS (
        SELECT 1
        FROM movie_info mi
        WHERE mi.movie_id = md.movie_id
        AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info LIKE '%Award%'
        )
    ) AS has_awards
FROM
    MovieDetails md
WHERE
    EXISTS (
        SELECT 1
        FROM movie_keyword mk
        WHERE mk.movie_id = md.movie_id
        AND mk.keyword_id IN (
            SELECT id FROM keyword WHERE keyword LIKE 'Action%'
        )
    )
ORDER BY
    md.production_year DESC, md.movie_id;
