WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY t.id, t.title, t.production_year
),
PopularTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.rank
    FROM RankedTitles rt
    WHERE rt.rank <= 5
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        COUNT(ci.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    JOIN PopularTitles pt ON ci.movie_id = pt.title_id
    GROUP BY a.id, a.name
),
CompanyDetails AS (
    SELECT 
        cn.name AS company_name,
        COUNT(mc.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM company_name cn
    JOIN movie_companies mc ON cn.id = mc.company_id
    JOIN title t ON mc.movie_id = t.id
    GROUP BY cn.name
)
SELECT 
    ai.actor_name,
    ai.movie_count AS total_movies_appeared,
    cd.company_name,
    cd.movie_count AS total_movies_produced,
    cd.titles
FROM ActorInfo ai
JOIN CompanyDetails cd ON cd.movie_count > 0
ORDER BY ai.movie_count DESC, cd.movie_count DESC;
