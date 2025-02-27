WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.name ORDER BY c.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT CONCAT(a.name, ' as ', r.role) ORDER BY a.name) AS cast
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
FinalBenchmark AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COALESCE(cd.cast, ARRAY[]::text[]) AS cast,
        COALESCE(md.keywords, ARRAY[]::text[]) AS keywords,
        COALESCE(md.companies, ARRAY[]::text[]) AS companies
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.cast,
    fb.keywords,
    fb.companies,
    LENGTH(fb.title) AS title_length,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = fb.movie_id) AS info_count
FROM 
    FinalBenchmark fb
WHERE 
    fb.production_year >= 2000
ORDER BY 
    fb.production_year DESC, 
    fb.title_length DESC
LIMIT 50;
