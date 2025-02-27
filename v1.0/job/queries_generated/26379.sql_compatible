
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        AVG(CASE WHEN r.role LIKE 'lead%' THEN 1.0 ELSE 0.0 END) AS lead_role_percentage
    FROM 
        aka_title AS m
    JOIN 
        cast_info AS c ON m.id = c.movie_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.lead_role_percentage,
        mk.keywords
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        MovieKeywords AS mk ON rm.movie_id = mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.lead_role_percentage,
    md.keywords,
    COUNT(DISTINCT ci.person_id) AS unique_cast_members
FROM 
    MovieDetails AS md
LEFT JOIN 
    cast_info AS ci ON md.movie_id = ci.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.total_cast, md.lead_role_percentage, md.keywords
ORDER BY 
    md.production_year DESC, md.total_cast DESC;
