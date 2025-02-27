WITH RankedTitles AS (
    SELECT
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY m.info_type_id DESC) AS rank_year
    FROM
        aka_title a
    JOIN
        movie_info m ON a.id = m.movie_id
    WHERE
        m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
),
DirectorCount AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS director_count
    FROM
        cast_info c
    JOIN
        role_type r ON c.role_id = r.id
    WHERE
        r.role = 'director'
    GROUP BY
        c.movie_id
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    rt.title,
    rt.production_year,
    dc.director_count,
    COALESCE(ks.keywords, 'No Keywords') AS keywords,
    COALESCE(rt.rank_year, 0) AS year_rank
FROM
    RankedTitles rt
LEFT JOIN
    DirectorCount dc ON rt.id = dc.movie_id
LEFT JOIN
    KeywordStats ks ON rt.id = ks.movie_id
WHERE
    rt.production_year >= 2000
ORDER BY
    rt.production_year DESC, 
    dc.director_count DESC, 
    rt.year_rank;
