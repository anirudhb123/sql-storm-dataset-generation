WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY m.id) AS total_cast,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY m.id) AS has_note_percentage,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
),
TitleKeywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
CompanyMovies AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS total_companies
    FROM 
        movie_companies m 
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, c.name, ct.kind
)
SELECT 
    tm.title,
    tk.keywords,
    cm.company_name,
    cm.company_type,
    rm.total_cast,
    ROUND(rm.has_note_percentage * 100, 2) AS note_percentage,
    CASE WHEN rm.rank <= 10 THEN 'Top 10 Recent' ELSE 'Others' END AS ranking_category
FROM 
    RankedMovies rm
LEFT JOIN 
    TitleKeywords tk ON rm.movie_id = tk.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.total_cast > 5 
    AND (cm.total_companies IS NULL OR cm.total_companies > 2)
ORDER BY 
    rm.production_year DESC, rm.title;
