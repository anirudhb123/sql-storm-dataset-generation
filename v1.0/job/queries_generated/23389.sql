WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title AS t
    WHERE t.production_year IS NOT NULL
),
CoActors AS (
    SELECT 
        ci1.person_id AS actor_id,
        ci2.person_id AS co_actor_id,
        t.title AS movie_title
    FROM cast_info AS ci1
    JOIN cast_info AS ci2 ON ci1.movie_id = ci2.movie_id AND ci1.person_id <> ci2.person_id
    JOIN title AS t ON ci1.movie_id = t.id
),
CompanyMovieCount AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT m.id) AS movie_count
    FROM movie_companies AS mc
    JOIN aka_title AS at ON mc.movie_id = at.movie_id
    JOIN title AS t ON at.movie_id = t.id
    WHERE mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
    GROUP BY mc.company_id
),
KeywordStatistics AS (
    SELECT 
        mk.keyword_id,
        COUNT(mk.movie_id) AS keyword_count
    FROM movie_keyword AS mk
    GROUP BY mk.keyword_id
)
SELECT 
    ak.name AS actor_name,
    ct.kind AS co_actor_type,
    rt.title,
    rt.production_year,
    CC.movie_count AS total_movies_produced_by_company,
    ks.keyword_count AS associated_keyword_count
FROM aka_name AS ak
JOIN cast_info AS ci ON ak.person_id = ci.person_id
JOIN RankedTitles AS rt ON ci.movie_id = rt.title_id
LEFT JOIN CoActors AS ca ON ak.person_id = ca.actor_id
LEFT JOIN comp_cast_type AS ct ON ca.co_actor_id = ct.id
LEFT JOIN CompanyMovieCount AS CC ON ci.movie_id = CC.company_id
LEFT JOIN KeywordStatistics AS ks ON rt.title_id = ks.keyword_id
WHERE (rt.year_rank <= 5 OR rt.production_year IS NULL)
AND (ks.keyword_count IS NOT NULL OR ks.keyword_count = 0)
ORDER BY rt.production_year DESC, ak.name;

