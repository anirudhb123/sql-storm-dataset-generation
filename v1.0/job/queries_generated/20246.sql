WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY count(ci.person_id) DESC) AS title_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
HighestRankedTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank = 1
),
PersonTitles AS (
    SELECT 
        ak.person_id,
        rt.title_id,
        rt.title AS title_name,
        at.production_year,
        COUNT(DISTINCT ak.name) AS total_names,
        STRING_AGG(DISTINCT ak.name, ', ') AS name_list
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        HighestRankedTitles rt ON ci.movie_id = rt.title_id
    GROUP BY 
        ak.person_id, rt.title_id, rt.title, at.production_year
)
SELECT 
    pt.person_id,
    pt.title_name,
    pt.production_year,
    pt.total_names,
    COALESCE(pt.name_list, 'No Names') AS name_list,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = pt.title_id) AS company_count,
    (SELECT COUNT(DISTINCT ki.keyword) 
     FROM movie_keyword mk 
     JOIN keyword ki ON mk.keyword_id = ki.id 
     WHERE mk.movie_id = pt.title_id) AS keyword_count,
    (SELECT MAX(mp.production_year) 
     FROM aka_title at
     LEFT JOIN movie_companies mc ON at.movie_id = mc.movie_id
     WHERE mc.company_id IN (
         SELECT id FROM company_name WHERE country_code IS NOT NULL
     )) AS latest_company_year,
    CASE 
        WHEN (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = pt.title_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')) > 0 
        THEN 'Box Office Data Exists' 
        ELSE 'No Box Office Data' 
    END AS box_office_status
FROM 
    PersonTitles pt
JOIN 
    role_type rt ON rt.id = (SELECT role_id FROM cast_info ci WHERE ci.person_id = pt.person_id AND ci.movie_id = pt.title_id)
WHERE 
    pt.total_names > 0
ORDER BY 
    pt.production_year DESC, pt.title_name;
