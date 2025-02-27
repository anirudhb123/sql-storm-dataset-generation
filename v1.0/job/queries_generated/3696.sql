WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
ActorNames AS (
    SELECT 
        ka.person_id,
        STRING_AGG(ka.name, ', ') AS actor_names
    FROM
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.person_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FilteredTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ac.actor_names,
        mci.company_names,
        mci.company_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        cast_info ci ON rt.title_id = ci.movie_id
    LEFT JOIN 
        ActorNames ac ON ci.person_id = ac.person_id
    LEFT JOIN 
        MovieCompanyInfo mci ON rt.title_id = mci.movie_id
    WHERE 
        rt.title_rank <= 5
),
FinalSelection AS (
    SELECT 
        ft.title_id,
        ft.title,
        ft.production_year,
        ft.actor_names,
        ft.company_names,
        COALESCE(ft.company_count, 0) AS company_count,
        CASE 
            WHEN ft.company_count IS NULL THEN 'No companies associated'
            ELSE 'Companies Available'
        END AS company_status
    FROM 
        FilteredTitles ft
)
SELECT 
    DISTINCT f.title,
    f.production_year,
    f.actor_names,
    f.company_names,
    f.company_count,
    f.company_status
FROM 
    FinalSelection f
WHERE 
    f.production_year >= 2000
ORDER BY 
    f.production_year DESC, 
    f.title;
