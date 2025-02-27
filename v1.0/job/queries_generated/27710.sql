WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT keyword.keyword) AS movie_keywords,
        GROUP_CONCAT(DISTINCT c.name) AS companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword ON mk.keyword_id = keyword.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY t.id
),
CastDetails AS (
    SELECT
        ci.movie_id,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS cast_names,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS total_cast_members
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        cd.cast_names,
        cd.total_cast_members,
        md.movie_keywords,
        md.companies
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
    WHERE 
        md.production_year >= 2000
    ORDER BY 
        md.production_year DESC,
        md.title
)
SELECT 
    *,
    LENGTH(title) AS title_length,
    LENGTH(cast_names) AS cast_names_length,
    LENGTH(movie_keywords) AS keyword_length,
    LENGTH(companies) AS companies_length
FROM 
    FinalBenchmark;
