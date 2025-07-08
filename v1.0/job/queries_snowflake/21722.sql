
WITH RecursiveActorDetails AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE t.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
KeywordActivity AS (
    SELECT 
        mk.movie_id, 
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM movie_keyword mk
    GROUP BY mk.movie_id
),
TitleProduction AS (
    SELECT
        t.id AS title_id,
        t.title,
        ct.kind AS title_kind,
        ROW_NUMBER() OVER (PARTITION BY ct.kind ORDER BY t.production_year DESC) AS kind_rank
    FROM aka_title t
    LEFT JOIN kind_type ct ON t.kind_id = ct.id
    WHERE t.production_year BETWEEN 2000 AND 2020
),
CorrelatedMovieStats AS (
    SELECT
        title_id,
        title,
        CASE 
            WHEN kp.keyword_count IS NULL THEN 'No Keywords' 
            ELSE 'Has Keywords' 
        END AS keyword_status,
        CASE 
            WHEN cp.total_companies IS NULL THEN 'Unknown Company Count' 
            ELSE CONCAT('Total Companies: ', cp.total_companies) 
        END AS company_info
    FROM TitleProduction t
    LEFT JOIN KeywordActivity kp ON t.title_id = kp.movie_id
    LEFT JOIN CompanyDetails cp ON t.title_id = cp.movie_id
)

SELECT
    ad.actor_id,
    ad.actor_name,
    ad.title,
    ad.production_year,
    cm.company_names,
    cs.keyword_count,
    rd.keyword_status,
    rd.company_info
FROM RecursiveActorDetails ad
LEFT JOIN CompanyDetails cm ON ad.movie_id = cm.movie_id
LEFT JOIN KeywordActivity cs ON ad.movie_id = cs.movie_id
LEFT JOIN CorrelatedMovieStats rd ON ad.movie_id = rd.title_id
WHERE ad.recent_movie_rank = 1
AND COALESCE(cs.keyword_count, 0) > 5
ORDER BY ad.actor_id, ad.production_year DESC;
