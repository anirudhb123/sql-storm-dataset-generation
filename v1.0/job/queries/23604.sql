WITH RecursiveMovies AS (
    SELECT 
        t.title AS movie_title,
        c.person_id,
        c.role_id,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS cast_order
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
),
CastRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role, 
        rm.movie_title,
        rm.cast_order
    FROM 
        RecursiveMovies rm
    JOIN 
        aka_name a ON rm.person_id = a.person_id
    JOIN 
        role_type r ON rm.role_id = r.id
),
ActorMovieDetails AS (
    SELECT 
        cm.id AS company_id,
        cm.name AS company_name,
        ct.kind AS company_type,
        title.title AS movie_title,
        COUNT(DISTINCT CAST(c.id AS VARCHAR)) AS num_cast_members
    FROM 
        company_name cm
    JOIN 
        movie_companies mc ON cm.id = mc.company_id
    JOIN 
        kind_type ct ON mc.company_type_id = ct.id
    JOIN 
        aka_title title ON mc.movie_id = title.id
    LEFT JOIN 
        cast_info c ON title.id = c.movie_id
    WHERE 
        cm.country_code IS NOT NULL AND 
        cm.name NOT LIKE '%Inc%' AND 
        title.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        cm.id, cm.name, ct.kind, title.title
),
FilteredMovies AS (
    SELECT 
        DISTINCT movie_title
    FROM 
        CastRoles
    WHERE 
        role IN (SELECT role FROM role_type WHERE role LIKE '%actor%')
      AND
        (SELECT COUNT(*) FROM CastRoles cr WHERE cr.movie_title = CastRoles.movie_title) > 3
),
FinalResult AS (
    SELECT 
        am.company_name,
        am.company_type,
        fm.movie_title,
        am.num_cast_members
    FROM 
        ActorMovieDetails am
    JOIN 
        FilteredMovies fm ON am.movie_title = fm.movie_title
    WHERE 
        am.num_cast_members > (SELECT AVG(num_cast_members) FROM ActorMovieDetails)
    ORDER BY 
        am.num_cast_members DESC
)
SELECT 
    fr.company_name,
    fr.company_type,
    fr.movie_title,
    fr.num_cast_members,
    CASE
        WHEN fr.num_cast_members IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status,
    NULLIF(fr.num_cast_members, 0) AS num_cast_non_zero
FROM 
    FinalResult fr
WHERE 
    fr.company_name IS NOT NULL 
  AND
    fr.company_type IS NOT NULL
  AND
    fr.movie_title IS NOT NULL
ORDER BY 
    fr.company_name, fr.movie_title;
