WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count,
        STRING_AGG(k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(ms.keyword_count, 0) AS total_keywords,
    COALESCE(cd.company_count, 0) AS total_companies,
    md.total_cast,
    md.cast_names,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic Film'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern Film'
        ELSE 'Recent Film'
    END AS film_category
FROM 
    MovieDetails md
LEFT JOIN 
    KeywordStats ms ON md.title_id = ms.movie_id
LEFT JOIN 
    CompanyDetails cd ON md.title_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;
