WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COALESCE(SUM(CASE WHEN ci.person_role_id = 1 THEN 1 ELSE 0 END), 0) AS actor_count,
        COALESCE(SUM(CASE WHEN ci.person_role_id = 2 THEN 1 ELSE 0 END), 0) AS director_count
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
MovieInfo AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.company_names,
        md.actor_count,
        md.director_count,
        rk.role AS role_type 
    FROM 
        MovieDetails md
    LEFT JOIN 
        role_type rk ON md.actor_count > 0 AND md.director_count > 0
),
FinalOutput AS (
    SELECT
        mi.movie_id,
        mi.title,
        mi.production_year,
        mi.keywords,
        mi.company_names,
        mi.actor_count,
        mi.director_count,
        COALESCE(mi.role_type, 'No roles found') AS role_type
    FROM
        MovieInfo mi
)
SELECT 
    *
FROM 
    FinalOutput
WHERE 
    production_year >= 2000
ORDER BY
    production_year DESC, title;
