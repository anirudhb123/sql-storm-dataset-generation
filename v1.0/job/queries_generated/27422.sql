WITH movie_author_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS authors,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year >= 2000
        AND m.title IS NOT NULL
    GROUP BY 
        m.id
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
movie_company_info AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        aka_title m ON mc.movie_id = m.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        m.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(mai.authors, 'No Authors') AS authors,
    COALESCE(kws.keyword_count, 0) AS total_keywords,
    COALESCE(mci.companies, 'No Companies') AS production_companies,
    COALESCE(mci.company_types, 'No Types') AS company_types
FROM 
    movie_author_info mai
FULL OUTER JOIN 
    keyword_summary kws ON mai.movie_id = kws.movie_id
FULL OUTER JOIN 
    movie_company_info mci ON mai.movie_id = mci.movie_id
ORDER BY 
    m.production_year DESC, 
    m.title;
