WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(CAST.id) AS total_cast,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info CAST ON cc.subject_id = CAST.id
    LEFT JOIN 
        aka_name c ON CAST.person_id = c.person_id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT kw.keyword) AS total_keywords,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.total_cast, 0) AS total_cast,
    COALESCE(md.cast_names, 'No Cast Available') AS cast_names,
    COALESCE(cd.total_companies, 0) AS total_companies,
    COALESCE(cd.company_names, 'No Companies Available') AS company_names,
    COALESCE(kd.total_keywords, 0) AS total_keywords,
    COALESCE(kd.keywords, 'No Keywords Available') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN 
    KeywordDetails kd ON md.movie_id = kd.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC,
    md.total_cast DESC NULLS LAST
LIMIT 100;
