WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
FilmCast AS (
    SELECT 
        c.movie_id,
        ka.name AS actor_name,
        ka.id AS actor_id,
        COUNT(DISTINCT c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name ka ON c.person_id = ka.person_id
    GROUP BY 
        c.movie_id, ka.name, ka.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        fc.actor_name,
        fc.role_count,
        mc.company_count,
        mc.company_names
    FROM 
        RankedTitles rt
    LEFT JOIN 
        FilmCast fc ON rt.title_id = fc.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rt.title_id = mc.movie_id
    WHERE 
        (fc.role_count IS NULL OR fc.role_count > 1) 
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(fm.actor_name, 'Unknown Actor') AS actor_name,
    NULLIF(fm.company_names, '') AS companies,
    CASE 
        WHEN fm.role_count IS NULL THEN 'No roles'
        ELSE CAST(fm.role_count AS text)
    END AS role_description
FROM 
    FilteredMovies fm
WHERE 
    fm.production_year >= 2000
ORDER BY 
    fm.production_year DESC, 
    fm.title;