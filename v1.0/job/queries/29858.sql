WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS title_rank
    FROM aka_title AS t
    JOIN aka_name AS a ON a.person_id = t.id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword AS mk
    GROUP BY mk.movie_id
),
CastMovieCount AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count
    FROM cast_info AS ci
    GROUP BY ci.movie_id
)
SELECT 
    rt.aka_name,
    rt.movie_title,
    rt.production_year,
    km.keyword_count,
    cc.cast_count
FROM RankedTitles AS rt
JOIN MovieKeywordCounts AS km ON rt.aka_id = km.movie_id
JOIN CastMovieCount AS cc ON rt.aka_id = cc.movie_id
WHERE rt.title_rank <= 5
  AND rt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Feature%')
ORDER BY rt.production_year DESC, LENGTH(rt.movie_title) DESC;
