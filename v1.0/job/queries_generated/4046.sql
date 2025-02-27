WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE NULL END), 0) AS avg_cast_role,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
RoleImpact AS (
    SELECT 
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS num_actors,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count,
        AVG(COALESCE(LENGTH(ci.note), 0)) AS avg_note_length
    FROM 
        cast_info ci
    GROUP BY 
        ci.role_id
)
SELECT 
    md.movie_id,
    md.title,
    md.avg_cast_role,
    md.total_keywords,
    ri.num_actors,
    ri.null_notes_count,
    ri.avg_note_length
FROM 
    MovieDetails md
LEFT JOIN 
    RoleImpact ri ON md.avg_cast_role = ri.role_id
WHERE 
    md.total_keywords > 5 AND 
    (ri.null_notes_count BETWEEN 1 AND 3 OR ri.avg_note_length > 10)
ORDER BY 
    md.rank_year, md.avg_cast_role DESC
LIMIT 50;
