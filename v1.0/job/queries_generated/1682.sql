WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title, 
        t.production_year,
        COALESCE(SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        COALESCE(MIN(t.production_year) OVER (PARTITION BY t.id), 0) AS earliest_year
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyMovies AS (
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
KeywordMovies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    cm.company_name,
    cm.company_type,
    km.keywords,
    CASE 
        WHEN md.earliest_year < 2000 THEN 'Classic'
        WHEN md.production_year >= 2020 THEN 'Recent'
        ELSE 'Contemporary' 
    END AS movie_category
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyMovies cm ON md.movie_id = cm.movie_id
LEFT JOIN 
    KeywordMovies km ON md.movie_id = km.movie_id
WHERE 
    md.cast_count > 0
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC, 
    md.title ASC;
