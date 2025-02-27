WITH movie_rankings AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(mn.production_year::decimal) AS avg_release_year
    FROM
        aka_title t
    JOIN
        complete_cast cc ON t.id = cc.movie_id
    JOIN
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN
        movie_info mi ON t.id = mi.movie_id
    JOIN
        name n ON ci.person_id = n.id
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') AND
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY
        t.id, t.title, t.production_year
),
keyword_rankings AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
),
final_rankings AS (
    SELECT 
        mr.movie_id,
        mr.title,
        mr.production_year,
        mr.cast_count,
        kr.keyword_count,
        (mr.cast_count * 0.6 + kr.keyword_count * 0.4) AS ranking_score
    FROM
        movie_rankings mr
    LEFT JOIN
        keyword_rankings kr ON mr.movie_id = kr.movie_id
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.cast_count,
    COALESCE(fr.keyword_count, 0) AS keyword_count,
    fr.ranking_score
FROM
    final_rankings fr
ORDER BY
    fr.ranking_score DESC
LIMIT 10;
