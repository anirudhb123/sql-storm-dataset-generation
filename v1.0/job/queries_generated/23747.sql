WITH RecursiveActorMovies AS (
    SELECT 
        a.id AS actor_id, 
        a.person_id,
        a.name,
        ct.kind AS company_type,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY at.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
    LEFT JOIN 
        movie_companies mc ON at.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        a.name IS NOT NULL
),
ActorAwards AS (
    SELECT 
        p.person_id,
        COUNT(DISTINCT m.id) AS award_count
    FROM 
        person_info p
    JOIN 
        movie_info mi ON p.person_id = mi.movie_id
    JOIN 
        title t ON mi.movie_id = t.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'award' LIMIT 1)
    GROUP BY 
        p.person_id
)
SELECT 
    ram.actor_id, 
    ram.name, 
    ram.movie_title, 
    ram.production_year, 
    COALESCE(aa.award_count, 0) AS total_awards,
    CASE 
        WHEN ram.movie_rank = 1 AND COALESCE(aa.award_count, 0) > 0 THEN 'Leading Actor with Awards'
        WHEN ram.movie_rank = 1 AND COALESCE(aa.award_count, 0) = 0 THEN 'Leading Actor without Awards'
        WHEN ram.movie_rank > 1 THEN 'Supporting Actor'
    END AS actor_status
FROM 
    RecursiveActorMovies ram
LEFT JOIN 
    ActorAwards aa ON ram.person_id = aa.person_id
WHERE 
    ram.production_year >= 2000
    AND ram.company_type LIKE 'Production%'
    AND (ram.movie_title IS NOT NULL OR ram.movie_rank < 5)
ORDER BY 
    ram.production_year DESC, 
    total_awards DESC
LIMIT 10;

-- Additional testing for NULL handling and edge cases
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title, 
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    md.movie_id,
    md.title,
    CASE 
        WHEN md.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_status
FROM 
    MovieDetails md
WHERE 
    md.company_count < 1
    OR md.title LIKE '%Old%'
ORDER BY 
    md.title ASC;
