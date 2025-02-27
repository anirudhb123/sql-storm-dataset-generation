WITH RECURSIVE MovieRelationships AS (
    SELECT 
        mc.movie_id,
        mc.company_id,
        cn.name AS company_name,
        1 AS level
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE cn.country_code = 'USA'
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        mc.company_id,
        cn.name AS company_name,
        mr.level + 1
    FROM MovieRelationships mr
    JOIN movie_companies mc ON mr.movie_id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE mr.level < 5
),

TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS row_num
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),

ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(t.production_year) AS latest_movie_year,
        STRING_AGG(DISTINCT t.title, ', ') AS titles
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title t ON ci.movie_id = t.id
    GROUP BY ak.name
    HAVING COUNT(DISTINCT t.id) > 10
),

FilteredTitles AS (
    SELECT 
        ti.title_id,
        ti.title
    FROM TitleInfo ti
    WHERE ti.row_num < 10
),

CompanyStats AS (
    SELECT 
        mr.movie_id,
        mr.company_name,
        COUNT(DISTINCT ci.person_id) AS total_actors
    FROM MovieRelationships mr
    JOIN cast_info ci ON mr.movie_id = ci.movie_id
    GROUP BY mr.movie_id, mr.company_name
)

SELECT 
    ad.actor_name,
    ad.movie_count,
    ad.latest_movie_year,
    ad.titles,
    cs.total_actors,
    CASE 
        WHEN cs.total_actors IS NULL THEN 'No Actors'
        ELSE 'Actors Present'
    END AS actor_status,
    ft.title AS filtered_title
FROM ActorDetails ad
LEFT JOIN CompanyStats cs ON ad.movie_count = cs.total_actors
JOIN FilteredTitles ft ON ft.title_id IN (SELECT DISTINCT movie_id FROM cast_info WHERE person_id IN (SELECT DISTINCT ak.person_id FROM aka_name ak WHERE ak.name = ad.actor_name))
WHERE ad.latest_movie_year BETWEEN 2000 AND 2023
ORDER BY ad.latest_movie_year DESC, ad.actor_name;
