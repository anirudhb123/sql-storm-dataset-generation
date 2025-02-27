WITH RecursiveCast AS (
    SELECT 
        c.person_id, 
        a.name AS actor_name, 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) as role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        c.nr_order IS NOT NULL
),

RankedActors AS (
    SELECT
        actor_name,
        COUNT(DISTINCT movie_title) AS total_movies,
        AVG(production_year) AS avg_year
    FROM 
        RecursiveCast
    GROUP BY 
        actor_name
),

FamousActors AS (
    SELECT 
        actor_name 
    FROM 
        RankedActors 
    WHERE 
        total_movies > (SELECT AVG(total_movies) FROM RankedActors) 
        AND avg_year < 2010
),

CompanyDetails AS (
    SELECT 
        m.movie_id,
        c.name AS company_name, 
        ct.kind AS company_type,
        mc.note AS company_note
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),

MovieWithFamousActors AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT f.actor_name) AS famous_actor_count,
        STRING_AGG(DISTINCT f.actor_name, ', ') AS actor_list
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        FamousActors f ON c.person_id = (SELECT id FROM aka_name WHERE name = f.actor_name LIMIT 1)
    GROUP BY 
        t.title
)

SELECT 
    m.movie_title,
    COALESCE(c.company_name, 'Unknown') AS company_name,
    COALESCE(c.company_type, 'Not Specified') AS company_type,
    m.famous_actor_count,
    m.actor_list,
    CASE 
        WHEN m.famous_actor_count > 0 THEN 'Has Famous Actors' 
        ELSE 'No Famous Actors' 
    END AS actor_fame_status 
FROM 
    MovieWithFamousActors m
LEFT JOIN 
    CompanyDetails c ON m.movie_title = c.movie_id
WHERE 
    m.famous_actor_count > 0 OR c.company_name IS NULL
ORDER BY 
    m.famous_actor_count DESC, m.movie_title
LIMIT 100;

