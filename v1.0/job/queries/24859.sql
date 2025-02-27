WITH RankedTitles AS (
    SELECT 
        at.title AS title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS title_rank,
        MAX(at.production_year) OVER () AS max_year
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
),
ActorRoles AS (
    SELECT 
        an.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN ci.note IS NOT NULL OR ci.note <> '' THEN 1 ELSE 0 END) AS roles_with_notes
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    JOIN 
        RankedTitles rt ON ci.movie_id = (SELECT id FROM aka_title WHERE title = rt.title AND production_year = rt.production_year LIMIT 1)
    GROUP BY 
        an.name
),
CompanyMovies AS (
    SELECT 
        cn.name AS company_name,
        COUNT(DISTINCT mc.movie_id) AS total_movies,
        STRING_AGG(DISTINCT at.title, ', ') AS movie_titles
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_title at ON mc.movie_id = at.movie_id
    WHERE 
        cn.country_code IS NOT NULL AND cn.country_code <> ''
    GROUP BY 
        cn.name
),
AwardWinningActors AS (
    SELECT 
        ai.actor_name,
        COALESCE(MAX(ai.movie_count), 0) AS movie_count,
        CASE 
            WHEN MAX(ai.movie_count) > 5 THEN 'Frequent Actor'
            ELSE 'Occasional Actor'
        END AS actor_status
    FROM 
        ActorRoles ai
    WHERE 
        EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.role_id IS NOT NULL)
            AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards') 
            AND mi.info IS NOT NULL
        )
    GROUP BY 
        ai.actor_name
)
SELECT 
    rt.title,
    rt.production_year,
    ar.actor_name,
    ar.movie_count,
    ar.roles_with_notes,
    cm.company_name,
    cm.total_movies,
    aw.actor_status
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorRoles ar ON ar.movie_count > 0
LEFT JOIN 
    CompanyMovies cm ON cm.total_movies > 0
FULL OUTER JOIN 
    AwardWinningActors aw ON ar.actor_name = aw.actor_name
WHERE 
    rt.title_rank = 1
ORDER BY 
    rt.production_year DESC, ar.movie_count DESC NULLS LAST;
