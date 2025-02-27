WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        row_number() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyCTE AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
ActorCTE AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COALESCE(person_info.info, 'No Info') AS personal_info,
        COUNT(ci.role_id) OVER (PARTITION BY ci.movie_id) AS cast_count
    FROM
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        person_info ON ci.person_id = person_info.person_id
    WHERE 
        ak.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        c.company_name,
        c.company_type,
        a.actor_name,
        a.personal_info,
        a.cast_count
    FROM 
        RecursiveMovieCTE r
    LEFT JOIN 
        CompanyCTE c ON r.title_id = c.movie_id
    LEFT JOIN 
        ActorCTE a ON r.title_id = a.movie_id
    WHERE 
        a.cast_count > 2
)
SELECT 
    f.title,
    f.production_year,
    STRING_AGG(DISTINCT f.company_name || ' (' || f.company_type || ')', '; ') AS companies,
    STRING_AGG(DISTINCT f.actor_name, ', ') AS actors,
    COUNT(DISTINCT f.actor_name) AS total_actors
FROM 
    FilteredMovies f
GROUP BY 
    f.title, f.production_year
HAVING 
    COUNT(DISTINCT f.actor_name) >= 3
ORDER BY 
    f.production_year DESC,
    f.title ASC
LIMIT 10;
