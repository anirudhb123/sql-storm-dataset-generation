WITH MovieRankings AS (
    SELECT
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_percentage,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.movie_id
    LEFT JOIN
        name p ON c.person_id = p.imdb_id
    GROUP BY
        t.title, t.production_year
),
AnotherRanking AS (
    SELECT
        t.title,
        p.name AS producer_name,
        COUNT(m.id) AS movie_count
    FROM
        movie_companies mc
    JOIN
        company_name p ON mc.company_id = p.imdb_id
    JOIN
        aka_title t ON mc.movie_id = t.id
    LEFT JOIN
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget')
    LEFT JOIN
        movie_link ml ON t.id = ml.movie_id
    GROUP BY
        t.title, p.name
)
SELECT
    m.title,
    m.production_year,
    m.total_cast,
    m.female_percentage,
    COALESCE(a.movie_count, 0) AS movie_count_by_producer,
    m.rank_by_cast
FROM
    MovieRankings m
LEFT JOIN
    AnotherRanking a ON m.title = a.title
WHERE
    m.rank_by_cast <= 5 AND m.female_percentage > 0.5
ORDER BY
    m.production_year DESC, m.rank_by_cast;
