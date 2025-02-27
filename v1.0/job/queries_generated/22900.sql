WITH TitleRanked AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),

ActorNames AS (
    SELECT 
        ak.person_id, 
        STRING_AGG(ak.name, ', ') AS full_name
    FROM aka_name ak
    GROUP BY ak.person_id
),

CastAndTitles AS (
    SELECT 
        c.person_id,
        c.movie_id,
        c.nr_order,
        ak.full_name,
        t.title,
        t.production_year
    FROM cast_info c
    JOIN ActorNames ak ON c.person_id = ak.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
),

CompanyDetails AS (
    SELECT 
        mc.movie_id, 
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS company_names
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    WHERE mc.note IS NOT NULL
    GROUP BY mc.movie_id
),

FinalOutput AS (
    SELECT 
        cat.title,
        cat.production_year,
        cat.full_name,
        cd.company_names,
        CASE 
            WHEN cd.company_names IS NULL THEN 'No Companies' 
            ELSE 'Companies Listed' 
        END AS company_status
    FROM CastAndTitles cat
    LEFT JOIN CompanyDetails cd ON cat.movie_id = cd.movie_id
)

SELECT 
    fo.title,
    fo.production_year,
    COALESCE(fo.full_name, 'Unknown Actor') AS actor_names,
    fo.company_names,
    fo.company_status,
    COUNT(*) OVER (PARTITION BY fo.production_year) AS movies_in_year,
    AVG(CASE 
            WHEN fo.production_year < 2000 THEN 1
            ELSE NULL 
        END) OVER () AS pre_2000_average
FROM FinalOutput fo
WHERE fo.production_year IN (SELECT DISTINCT production_year FROM title WHERE production_year >= 1990)
ORDER BY fo.production_year DESC, fo.title;
