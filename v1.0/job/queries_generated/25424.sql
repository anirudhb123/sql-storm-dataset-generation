WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(MIN(CASE WHEN ci.kind_id IS NOT NULL THEN ct.kind END), 'N/A') AS comp_cast_type
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        comp_cast_type ct ON cc.status_id = ct.id
    GROUP BY 
        m.id
),
production_details AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.total_cast,
    md.actors,
    md.keywords,
    pd.companies,
    pd.company_types,
    CONCAT('Movie: ', md.movie_title, ' | Released: ', md.production_year) AS movie_info
FROM 
    movie_details md
LEFT JOIN 
    production_details pd ON md.movie_id = pd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
