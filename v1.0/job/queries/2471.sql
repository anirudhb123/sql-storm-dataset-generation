WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.has_note_ratio,
        cd.company_name,
        cd.company_type,
        kd.keywords,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.total_cast DESC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.movie_id = cd.movie_id
    LEFT JOIN 
        KeywordDetails kd ON md.movie_id = kd.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    total_cast,
    has_note_ratio,
    company_name,
    company_type,
    keywords,
    rank
FROM 
    RankedMovies
WHERE 
    (production_year >= 2000 AND total_cast > 5) 
    OR (has_note_ratio > 0.5 AND company_type IS NOT NULL)
ORDER BY 
    production_year, rank;
