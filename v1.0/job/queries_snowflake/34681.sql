
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL 
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id 
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS actor_count,
        LISTAGG(a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieCompaniesDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(mi.info) AS movie_plot_summary 
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        LOWER(it.info) LIKE '%plot%' 
    GROUP BY 
        mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cd.actor_count, 0) AS total_actors,
    COALESCE(cd.actors, 'No actors listed') AS actors,
    COALESCE(mcd.companies, 'No company listed') AS production_companies,
    COALESCE(mi.movie_plot_summary, 'No summary available') AS plot_summary,
    mh.depth
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastDetails cd ON mh.movie_id = cd.movie_id
LEFT JOIN 
    MovieCompaniesDetails mcd ON mh.movie_id = mcd.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
ORDER BY 
    mh.production_year DESC, mh.depth ASC, mh.title;
