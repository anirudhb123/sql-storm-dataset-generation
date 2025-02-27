WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ak.name AS aka_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.role_id) AS roles,
        GROUP_CONCAT(DISTINCT co.name) AS companies,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    WHERE 
        t.production_year BETWEEN 1990 AND 2023
    GROUP BY 
        t.id, ak.name, t.production_year
    HAVING 
        COUNT(DISTINCT ca.person_id) > 5
),
KeywordSummary AS (
    SELECT 
        keyword, 
        COUNT(DISTINCT title_id) AS movie_count
    FROM 
        MovieDetails
    GROUP BY 
        keyword
),
TopKeywords AS (
    SELECT 
        keyword 
    FROM 
        KeywordSummary 
    ORDER BY 
        movie_count DESC 
    LIMIT 10
)
SELECT 
    md.title,
    md.production_year,
    md.aka_name,
    md.keywords,
    md.roles,
    md.companies,
    md.cast_count
FROM 
    MovieDetails md
JOIN 
    TopKeywords tk ON md.keywords LIKE CONCAT('%', tk.keyword, '%')
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
