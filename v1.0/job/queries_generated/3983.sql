WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
CompanyMovieCount AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.company_id
)
SELECT 
    a.name AS actor_name,
    rt.title AS movie_title,
    rt.production_year,
    amc.movie_count AS actor_movie_count,
    cmc.movie_count AS company_movie_count,
    COALESCE(cn.name, 'Unknown') AS company_name,
    CASE 
        WHEN cmc.movie_count > 10 THEN 'Frequent Collaborator'
        ELSE 'Occasional Collaborator'
    END AS collaboration_status
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    RankedTitles rt ON ci.movie_id = rt.title_id AND rt.rn <= 5
LEFT JOIN 
    movie_companies mc ON mc.movie_id = ci.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    ActorMovieCount amc ON a.person_id = amc.person_id
JOIN 
    CompanyMovieCount cmc ON mc.company_id = cmc.company_id
WHERE 
    a.name IS NOT NULL
    AND rt.title IS NOT NULL
    AND amc.movie_count > 0
ORDER BY 
    rt.production_year DESC,
    a.name;
