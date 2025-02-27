WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        r.role AS role_in_movie,
        t.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        title t ON c.movie_id = t.id
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyMovieInfo AS (
    SELECT 
        c.name AS company_name,
        t.title AS movie_title,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        title t ON mc.movie_id = t.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CombinedInfo AS (
    SELECT 
        a.actor_name,
        a.movie_title,
        a.role_in_movie,
        a.production_year,
        cm.company_name,
        cm.company_type
    FROM 
        ActorMovieInfo a
    LEFT JOIN 
        CompanyMovieInfo cm ON a.movie_title = cm.movie_title
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    COALESCE(role_in_movie, 'Unknown Role') AS role_in_movie,
    company_name,
    company_type
FROM 
    CombinedInfo
WHERE 
    (company_type IS NOT NULL OR production_year >= 2000)
    AND actor_name LIKE 'A%' 
    AND (EXISTS (
        SELECT 
            1 
        FROM 
            movie_keyword mk 
        WHERE 
            mk.movie_id = (SELECT id FROM title WHERE title = CombinedInfo.movie_title LIMIT 1)
            AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%')
    ) OR production_year BETWEEN 1990 AND 2020)
ORDER BY 
    production_year DESC, actor_name;
