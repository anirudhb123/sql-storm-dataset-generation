WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id
),
RoleSummary AS (
    SELECT 
        ci.role_id,
        COUNT(*) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY ci.role_id ORDER BY COUNT(*) DESC) AS role_rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
),
MovieRoles AS (
    SELECT 
        md.movie_id,
        COUNT(CASE WHEN rs.role_rank <= 3 THEN 1 END) AS top_roles_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        RoleSummary rs ON rs.role_id IN (SELECT role_id FROM cast_info WHERE movie_id = md.movie_id)
    GROUP BY 
        md.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.cast_count,
    COALESCE(mr.top_roles_count, 0) AS top_roles_count
FROM 
    MovieDetails md
LEFT JOIN 
    MovieRoles mr ON md.movie_id = mr.movie_id
WHERE 
    md.cast_count > 5 AND 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC;
