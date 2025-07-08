
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cr.role, 'Unknown') AS role,
        cr.role_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles cr ON rm.movie_id = cr.movie_id
    WHERE 
        rm.rank_year <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        MAX(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN mi.info END) AS budget,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.budget, 'Unknown') AS budget,
    COALESCE(md.company_names, 'No Companies') AS company_names,
    SUM(COALESCE(cr.role_count, 0)) AS total_roles
FROM 
    MovieDetails md
LEFT JOIN 
    CastRoles cr ON md.movie_id = cr.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.budget, md.company_names
ORDER BY 
    md.production_year DESC, md.title;
