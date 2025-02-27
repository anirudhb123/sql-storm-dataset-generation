WITH RecursiveMovieCTE AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mci.note AS company_note,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn
    FROM
        aka_title mt
    LEFT JOIN
        movie_companies mci ON mt.id = mci.movie_id
    WHERE
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%drama%')
        OR mt.production_year IS NULL
),
KnownDirectors AS (
    SELECT
        ci.movie_id,
        ak.name AS director_name,
        ak.id AS director_id
    FROM
        cast_info ci
    INNER JOIN
        aka_name ak ON ci.person_id = ak.person_id
    WHERE
        ci.person_role_id = (SELECT id FROM role_type WHERE role = 'director')
),
FilteredMovies AS (
    SELECT 
        m.movie_id, 
        m.title,
        COALESCE(d.director_name, 'Unknown Director') AS director_name,
        mn.value_count,
        COUNT(DISTINCT km.keyword) AS keyword_count
    FROM
        RecursiveMovieCTE m
    LEFT JOIN
        KnownDirectors d ON m.movie_id = d.movie_id
    LEFT JOIN (
        SELECT movie_id, COUNT(*) AS value_count
        FROM movie_info
        WHERE info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%rating%')
        GROUP BY movie_id
    ) mn ON mn.movie_id = m.movie_id
    LEFT JOIN movie_keyword km ON m.movie_id = km.movie_id
    GROUP BY m.movie_id, m.title, d.director_name, mn.value_count
)
SELECT
    m.title,
    m.production_year,
    m.director_name,
    m.value_count AS rating_info_count,
    m.keyword_count,
    CASE 
        WHEN m.production_year IS NULL THEN 'Year Not Recorded' 
        WHEN m.production_year < 2000 THEN 'Classic'
        ELSE 'Modern' 
    END AS era_type,
    COALESCE(m.keyword_count, 0) - COALESCE(m.value_count, 0) AS keyword_minus_rating
FROM
    FilteredMovies m
WHERE
    (m.production_year IS NOT NULL AND m.production_year > 1990)
    OR (m.keyword_count IS NULL AND m.value_count IS NULL)
ORDER BY
    CASE m.era_type
        WHEN 'Classic' THEN 1
        WHEN 'Modern' THEN 2
        ELSE 3
    END,
    m.title;
