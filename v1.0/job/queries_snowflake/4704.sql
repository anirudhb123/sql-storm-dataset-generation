
WITH RankedTitles AS (
    SELECT t.id AS title_id, 
           t.title, 
           t.production_year,
           ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), TitleKeywords AS (
    SELECT mt.movie_id, 
           LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
), ActorCount AS (
    SELECT ci.movie_id, 
           COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
), MovieCompanyInfo AS (
    SELECT mc.movie_id,
           COUNT(DISTINCT mc.company_id) AS company_count,
           LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT rt.title, 
       rt.production_year, 
       COALESCE(ak.keywords, 'No Keywords') AS keywords,
       COALESCE(ac.actor_count, 0) AS actor_count,
       COALESCE(mci.company_count, 0) AS company_count,
       mci.company_names
FROM RankedTitles rt
LEFT JOIN TitleKeywords ak ON rt.title_id = ak.movie_id
LEFT JOIN ActorCount ac ON rt.title_id = ac.movie_id
LEFT JOIN MovieCompanyInfo mci ON rt.title_id = mci.movie_id
WHERE rt.rank = 1
ORDER BY rt.production_year DESC, rt.title;
