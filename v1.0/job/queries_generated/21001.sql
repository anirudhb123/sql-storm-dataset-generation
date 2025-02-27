WITH Recursive CastCTE AS 
(
    SELECT ci.movie_id,
           ci.person_id,
           ci.role_id,
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS rn
    FROM cast_info ci
),
TitleCTE AS 
(
    SELECT t.id AS title_id,
           t.title,
           t.production_year,
           t.kind_id,
           COALESCE(mi.info, 'No info available') AS movie_info
    FROM title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    WHERE t.production_year IS NOT NULL
),
KeywordCTE AS 
(
    SELECT k.keyword, 
           COUNT(mk.movie_id) AS movie_count
    FROM keyword k
    JOIN movie_keyword mk ON k.id = mk.keyword_id
    GROUP BY k.keyword
    HAVING COUNT(mk.movie_id) > 1
),
NameAggregation AS 
(
    SELECT akn.person_id,
           STRING_AGG(DISTINCT akn.name, ', ') AS all_names,
           COUNT(DISTINCT akn.id) AS name_count
    FROM aka_name akn
    GROUP BY akn.person_id
)
SELECT t.title AS movie_title,
       CASE 
           WHEN kc.movie_count IS NULL THEN 'No keywords associated'
           ELSE kc.movie_count::text || ' films use this keyword in association.'
       END AS keyword_info,
       c.all_names,
       t.movie_info,
       c.rn,
       CASE 
           WHEN c.person_id IS NOT NULL THEN 'Cast present'
           ELSE 'No cast information'
       END AS cast_availability
FROM TitleCTE t
LEFT JOIN CastCTE c ON t.title_id = c.movie_id
LEFT JOIN KeywordCTE kc ON t.title_id IN (SELECT mk.movie_id FROM movie_keyword mk WHERE mk.keyword_id = kc.id)
LEFT JOIN NameAggregation na ON c.person_id = na.person_id
WHERE t.production_year >= 2000
AND (t.kind_id IS NOT NULL OR t.kind_id IN 
       (SELECT kind_id FROM kind_type WHERE kind LIKE '%Drama%'))
ORDER BY t.production_year DESC NULLS LAST, 
         rnk IS NOT NULL DESC, 
         t.title;
