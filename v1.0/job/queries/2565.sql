WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword_id) AS total_keywords
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.total_cast_members, 0) AS total_cast_members,
    md.cast_names,
    COALESCE(kc.total_keywords, 0) AS total_keywords,
    COALESCE(cd.total_companies, 0) AS total_companies,
    cd.company_names
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordCount kc ON md.movie_id = kc.movie_id
LEFT JOIN 
    CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE 
    (md.total_cast_members > 5 OR kc.total_keywords IS NOT NULL)
ORDER BY 
    md.production_year DESC, 
    md.total_cast_members DESC;
