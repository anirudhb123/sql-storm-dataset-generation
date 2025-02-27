WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 1990 AND 2020
    GROUP BY 
        m.id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(CASE WHEN ci.kind IS NOT NULL THEN ci.kind END) AS lead_cast_role
    FROM 
        cast_info c
    LEFT JOIN 
        comp_cast_type ci ON c.person_role_id = ci.id
    GROUP BY 
        c.movie_id
),
CombinedDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        cd.total_cast,
        cd.lead_cast_role,
        COALESCE(md.keywords, '{}') AS movie_keywords 
    FROM 
        MovieDetails md
    JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    cd.title, 
    cd.production_year, 
    cd.total_cast,
    cd.lead_cast_role,
    CASE 
        WHEN cd.total_cast > 10 THEN 'Large Ensemble'
        WHEN cd.total_cast BETWEEN 5 AND 10 THEN 'Moderate Ensemble'
        ELSE 'Small Cast'
    END AS cast_size_category,
    ARRAY_LENGTH(cd.movie_keywords, 1) AS keyword_count
FROM 
    CombinedDetails cd
WHERE 
    cd.lead_cast_role IS NOT NULL 
ORDER BY 
    cd.production_year DESC, 
    cd.total_cast DESC 
FETCH FIRST 50 ROWS ONLY;
