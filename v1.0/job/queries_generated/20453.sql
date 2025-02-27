WITH Recursive CastHierarchy AS (
    SELECT ci.id AS cast_id, ci.person_id, ci.movie_id, ci.nr_order, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank,
           1 AS level
    FROM cast_info ci
    WHERE ci.nr_order IS NOT NULL
    UNION ALL
    SELECT ci.id AS cast_id, ci.person_id, ci.movie_id, ci.nr_order, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank,
           ch.level + 1 AS level
    FROM cast_info ci
    JOIN CastHierarchy ch ON ci.movie_id = ch.movie_id AND ci.nr_order > ch.nr_order
    WHERE ch.level < 10
), MovieDetails AS (
    SELECT mt.id AS movie_id, mt.title, mt.production_year, 
           COUNT(DISTINCT ci.person_id) AS total_cast, 
           AVG(ch.level) AS avg_role_depth
    FROM aka_title mt
    LEFT JOIN cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN CastHierarchy ch ON ci.id = ch.cast_id
    WHERE mt.production_year >= 2000
    GROUP BY mt.id
), PopularKeywords AS (
    SELECT mk.movie_id, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
    HAVING COUNT(mk.keyword_id) > 5
), Hints AS (
    SELECT DISTINCT ci.note
    FROM cast_info ci
    WHERE ci.note IS NOT NULL AND LENGTH(ci.note) > 20
), RankedMovies AS (
    SELECT md.movie_id, md.title,
           CASE 
               WHEN md.total_cast > 20 THEN 'Blockbuster'
               WHEN md.total_cast BETWEEN 10 AND 20 THEN 'Medium'
               ELSE 'Indie'
           END AS movie_type,
           RANK() OVER (ORDER BY md.avg_role_depth DESC, md.total_cast DESC) AS rank
    FROM MovieDetails md
    JOIN PopularKeywords pk ON md.movie_id = pk.movie_id
)
SELECT rm.title, rm.movie_type, rm.rank, hk.note AS helpful_hints
FROM RankedMovies rm
LEFT JOIN Hints hk ON rm.movie_id IN (
    SELECT ci.movie_id
    FROM cast_info ci
    WHERE ci.note LIKE '%hero%' OR ci.note LIKE '%winner%'
) 
WHERE rm.rank <= 10
ORDER BY rm.rank;
