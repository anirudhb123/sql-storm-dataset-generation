WITH RECURSIVE MovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
CastEnhanced AS (
    SELECT 
        ci.movie_id,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        coalesce(ci.cast_count, 0) AS total_cast,
        coalesce(ci.cast_names, 'No Cast') AS cast_names,
        ci.company_name,
        ci.company_type
    FROM 
        MovieCTE m
    LEFT JOIN 
        CastEnhanced ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        CompanyInfo ci ON m.movie_id = ci.movie_id AND ci.company_rank = 1
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.cast_names,
    CASE 
        WHEN md.company_name IS NOT NULL THEN md.company_name 
        ELSE 'Independent' 
    END AS production_company,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MAX(IIF(m.production_year < 2010, 'Old Film', 'New Film')) AS era
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    md.total_cast > 5
GROUP BY 
    md.movie_id, md.title, md.production_year, md.total_cast,
    md.cast_names, md.company_name
ORDER BY 
    md.production_year DESC, md.title;
