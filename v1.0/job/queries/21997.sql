WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Movie%')
),
FilteredTitles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.title_rank <= 5
),
CastDetails AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.nr_order,
        ARRAY_AGG(aka.name) AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    GROUP BY 
        ci.person_id, ci.movie_id, ci.nr_order
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        ft.movie_id,
        ft.title,
        ft.production_year,
        cd.actor_names,
        ci.company_name,
        ci.company_type,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        CastDetails cd ON ft.movie_id = cd.movie_id
    LEFT JOIN 
        movie_keyword mk ON ft.movie_id = mk.movie_id
    LEFT JOIN 
        CompanyInfo ci ON ft.movie_id = ci.movie_id
    GROUP BY 
        ft.movie_id, ft.title, ft.production_year, cd.actor_names, ci.company_name, ci.company_type
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_names[1], 'Unknown') AS lead_actor,
    md.company_name,
    md.company_type,
    coalesce(md.keyword_count, 0) AS total_keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title;
