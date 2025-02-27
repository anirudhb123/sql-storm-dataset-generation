WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorTitles AS (
    SELECT 
        a.name AS actor_name,
        rt.title,
        rt.production_year,
        rc.nr_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RankedTitles rt ON ci.movie_id = rt.title_id
    LEFT JOIN 
        role_type rc ON ci.role_id = rc.id
), 
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT mi.info SEPARATOR '; ') AS additional_info
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget')
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id, c.name
)
SELECT 
    at.actor_name,
    at.title,
    at.production_year,
    cm.company_name,
    cm.additional_info
FROM 
    ActorTitles at
LEFT JOIN 
    CompanyMovieInfo cm ON at.title = cm.movie_id
WHERE 
    at.year_rank <= 5
ORDER BY 
    at.production_year DESC, at.actor_name;
