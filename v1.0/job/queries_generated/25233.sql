WITH TitleStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COUNT(mk.movie_id) AS keyword_count,
        MIN(m.production_year) AS first_release,
        MAX(m.production_year) AS latest_release
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        aka_title at ON t.id = at.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info_idx mii ON t.id = mii.movie_id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id
),
ActorStats AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        COUNT(ci.movie_id) AS movies_played,
        STRING_AGG(DISTINCT t.title, ', ') AS movie_titles
    FROM 
        aka_name p
    LEFT JOIN 
        cast_info ci ON p.person_id = ci.person_id
    LEFT JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        p.name LIKE '%Smith%'
    GROUP BY 
        p.id
),
CompanyStats AS (
    SELECT 
        cn.id AS company_id,
        cn.name AS company_name,
        COUNT(m.id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies_produced
    FROM 
        company_name cn
    LEFT JOIN 
        movie_companies mc ON cn.id = mc.company_id
    LEFT JOIN 
        title t ON mc.movie_id = t.id
    LEFT JOIN 
        title_stats ts ON t.id = ts.title_id
    WHERE 
        cn.country_code = 'USA'
    GROUP BY 
        cn.id
)
SELECT 
    ts.title_id,
    ts.title,
    ts.keyword_count,
    ts.first_release,
    ts.latest_release,
    as.actor_name,
    as.movies_played,
    cs.company_name,
    cs.movie_count
FROM 
    TitleStats ts
LEFT JOIN 
    ActorStats as ON ts.title_id IN (SELECT movie_id FROM cast_info WHERE person_id = as.person_id)
LEFT JOIN 
    CompanyStats cs ON ts.title_id IN (SELECT movie_id FROM movie_companies WHERE company_id = cs.company_id)
ORDER BY 
    ts.latest_release DESC, 
    ts.keyword_count DESC;
