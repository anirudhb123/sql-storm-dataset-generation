WITH RecursiveActorInfo AS (
    SELECT
        ai.id AS actor_id,
        ai.person_id,
        ak.name AS actor_name,
        COUNT(c.movie_id) AS movie_count,
        MAX(t.production_year) AS last_seen_year
    FROM aka_name ak
    JOIN cast_info c ON ak.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE ak.name IS NOT NULL
    GROUP BY ai.id, ak.person_id, ak.name
    HAVING COUNT(c.movie_id) > 5 AND MAX(t.production_year) < 2020
),
DistinctTitles AS (
    SELECT DISTINCT
        t.title,
        t.production_year,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year IS NOT NULL AND t.production_year >= 2000
    GROUP BY t.title, t.production_year
    HAVING keyword_count > 3
),
ActorTitleInfo AS (
    SELECT
        ai.actor_id,
        ai.actor_name,
        dt.title,
        dt.production_year,
        DENSE_RANK() OVER (PARTITION BY ai.actor_id ORDER BY dt.production_year DESC) AS rank_within_actor
    FROM RecursiveActorInfo ai
    JOIN cast_info c ON ai.person_id = c.person_id
    JOIN aka_title dt ON c.movie_id = dt.id
    WHERE ai.last_seen_year > 2015
),
MoviesAndCompanies AS (
    SELECT
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
    FROM aka_title t
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code IS NULL OR cn.country_code = ''
    GROUP BY t.title, t.production_year
),
FinalResult AS (
    SELECT
        ati.actor_name,
        ati.title,
        ati.production_year,
        mac.company_names,
        CASE 
            WHEN mac.company_names IS NULL THEN 'No Companies'
            ELSE mac.company_names
        END AS companies_status
    FROM ActorTitleInfo ati
    LEFT JOIN MoviesAndCompanies mac ON ati.title = mac.title AND ati.production_year = mac.production_year
)
SELECT
    fr.actor_name,
    fr.title,
    fr.production_year,
    fr.companies_status,
    COALESCE(fr.production_year - (SELECT MIN(t.production_year) FROM aka_title t), 0) AS years_since_first_release
FROM FinalResult fr
WHERE fr.companies_status <> 'No Companies'
ORDER BY fr.production_year DESC, fr.actor_name
FETCH FIRST 100 ROWS ONLY;
