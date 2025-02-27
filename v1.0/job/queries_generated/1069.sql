WITH MovieTitles AS (
    SELECT t.id AS title_id, t.title, t.production_year, t.kind_id
    FROM aka_title AS t
    WHERE t.production_year >= 2000
), 
CastDetails AS (
    SELECT c.movie_id, COUNT(DISTINCT c.person_id) AS num_actors
    FROM cast_info AS c
    GROUP BY c.movie_id
), 
Companies AS (
    SELECT mc.movie_id, COUNT(DISTINCT c.id) AS num_companies
    FROM movie_companies AS mc
    JOIN company_name AS c ON mc.company_id = c.id
    GROUP BY mc.movie_id
),
KeywordCounts AS (
    SELECT mk.movie_id, COUNT(DISTINCT k.keyword) AS num_keywords
    FROM movie_keyword AS mk
    JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT mt.title, mt.production_year, 
       COALESCE(cd.num_actors, 0) AS actor_count, 
       COALESCE(co.num_companies, 0) AS company_count, 
       COALESCE(kc.num_keywords, 0) AS keyword_count,
       ROW_NUMBER() OVER (PARTITION BY mt.kind_id ORDER BY mt.production_year DESC) AS ranking
FROM MovieTitles AS mt
LEFT JOIN CastDetails AS cd ON mt.title_id = cd.movie_id
LEFT JOIN Companies AS co ON mt.title_id = co.movie_id
LEFT JOIN KeywordCounts AS kc ON mt.title_id = kc.movie_id
WHERE (COALESCE(cd.num_actors, 0) > 5 OR COALESCE(co.num_companies, 0) > 2)
AND mt.production_year IS NOT NULL
ORDER BY mt.production_year DESC, ranking;
