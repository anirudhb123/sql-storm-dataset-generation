WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actor_count_rank
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN cast_info ci ON t.id = ci.movie_id
    WHERE t.production_year IS NOT NULL
    GROUP BY t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ci.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
),
TitleKeywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(mk.keyword, ', ') AS keywords_aggregated
    FROM movie_keyword mk
    JOIN title mt ON mk.movie_id = mt.id
    GROUP BY mt.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT c.name || ' (' || ct.kind || ')') AS companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    ad.actor_name,
    ad.actor_order,
    tk.keywords_aggregated,
    ci.companies,
    ROUND(EXTRACT(EPOCH FROM age(NOW(), to_timestamp(tm.production_year::text || '0101', 'YYYYMMDD')))/31536000, 2) AS movie_age,
    CASE 
        WHEN NULLIF(ci.companies, '') IS NULL THEN 'No companies associated'
        ELSE 'Companies listed'
    END AS company_association_status
FROM RankedMovies tm
LEFT JOIN ActorDetails ad ON tm.movie_id = ad.movie_id
LEFT JOIN TitleKeywords tk ON tm.movie_id = tk.movie_id
LEFT JOIN CompanyInfo ci ON tm.movie_id = ci.movie_id
WHERE tm.actor_count_rank = 1
ORDER BY tm.production_year DESC, ad.actor_order
FETCH FIRST 10 ROWS ONLY;
