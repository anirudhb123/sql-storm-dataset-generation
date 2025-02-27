
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        t.id AS title_id
    FROM 
        aka_title t
        LEFT JOIN cast_info cc ON t.id = cc.movie_id
        LEFT JOIN aka_name a ON cc.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, t.id
),
GenreInfo AS (
    SELECT 
        t.id AS title_id,
        kt.kind AS genre
    FROM 
        title t
        JOIN kind_type kt ON t.kind_id = kt.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
        JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieSummary AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_count,
        md.actors,
        gi.genre,
        ci.companies
    FROM 
        MovieDetails md
        LEFT JOIN GenreInfo gi ON md.title_id = gi.title_id
        LEFT JOIN CompanyInfo ci ON md.title_id = ci.movie_id
)
SELECT 
    title,
    production_year,
    cast_count,
    actors,
    STRING_AGG(DISTINCT genre, ', ') AS genres,
    COALESCE(companies, 'No companies found') AS companies
FROM 
    MovieSummary
GROUP BY 
    title, production_year, cast_count, actors, companies
ORDER BY 
    production_year DESC, cast_count DESC;
