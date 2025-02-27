WITH RecursiveRole AS (
    SELECT ci.movie_id, r.role, 
           ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order ASC) AS role_order
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
),
MovieDetails AS (
    SELECT t.title, 
           t.production_year,
           ct.kind AS company_type, 
           ARRAY_AGG(DISTINCT r.role) AS roles,
           STRING_AGG(DISTINCT ak.name, ', ') AS alias_names
    FROM aka_title t 
    LEFT JOIN movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY t.id, t.title, t.production_year, ct.kind
),
KeywordCount AS (
    SELECT mk.movie_id, COUNT(mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
FinalStats AS (
    SELECT md.title, 
           md.production_year,
           COALESCE(kc.keyword_count, 0) AS keyword_count,
           COUNT(rr.role) AS total_cast,
           md.company_type,
           md.alias_names
    FROM MovieDetails md
    LEFT JOIN KeywordCount kc ON md.movie_id = kc.movie_id
    LEFT JOIN RecursiveRole rr ON md.movie_id = rr.movie_id
    GROUP BY md.title, md.production_year, kc.keyword_count, md.company_type, md.alias_names
)
SELECT fs.title AS movie_title,
       fs.production_year,
       fs.total_cast,
       fs.keyword_count,
       CASE 
           WHEN fs.keyword_count > 0 THEN 'Keywords Available'
           ELSE 'No Keywords'
       END AS keyword_status,
       fs.company_type,
       CASE 
           WHEN fs.total_cast > 0 THEN fs.alias_names
           ELSE 'Unknown Actors'
       END AS actor_aliases
FROM FinalStats fs
WHERE fs.production_year IS NOT NULL
  AND fs.total_cast > 2
ORDER BY fs.production_year DESC, fs.total_cast DESC;
