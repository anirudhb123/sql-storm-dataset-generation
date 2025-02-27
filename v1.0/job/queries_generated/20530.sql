WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
DetailedMovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(cc.company_count, 0) AS company_count,
        rt.title_rank
    FROM 
        aka_title t
    LEFT JOIN ActorRoles ac ON t.id = ac.movie_id
    LEFT JOIN CompanyCounts cc ON t.id = cc.movie_id
    JOIN RankedTitles rt ON t.id = rt.title_id
),
FinalSelection AS (
    SELECT 
        d.title,
        d.production_year,
        d.actor_count,
        d.company_count,
        CASE 
            WHEN d.actor_count > 0 AND d.company_count > 0 THEN 'Both actors and companies exist'
            WHEN d.actor_count > 0 AND d.company_count = 0 THEN 'Only actors exist'
            WHEN d.company_count > 0 AND d.actor_count = 0 THEN 'Only companies exist'
            ELSE 'Neither actors nor companies exist'
        END AS existence_summary
    FROM 
        DetailedMovieInfo d
    WHERE 
        d.title_rank <= 5
)

SELECT 
    fs.title,
    fs.production_year,
    fs.actor_count,
    fs.company_count,
    fs.existence_summary,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = fs.movie_id AND mi.info_type_id IN (1, 2)) AS relevant_info_count
FROM 
    FinalSelection fs
WHERE 
    fs.actor_count + fs.company_count > 0
ORDER BY 
    fs.production_year DESC, 
    fs.actor_count DESC, 
    fs.company_count DESC;
