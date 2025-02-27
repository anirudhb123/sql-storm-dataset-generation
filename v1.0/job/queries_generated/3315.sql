WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    JOIN 
        aka_name a ON t.id = a.id
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        ct.kind AS role_type,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id, ct.kind
),
MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COALESCE(r.year_rank, 0) AS title_rank,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = t.id) AS total_cast,
        (SELECT STRING_AGG(DISTINCT p.info, ', ') FROM person_info p WHERE p.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = t.id)) AS cast_infos
    FROM 
        title t
    LEFT JOIN 
        RankedTitles r ON t.id = r.aka_id
)
SELECT 
    md.title_id,
    md.title,
    md.title_rank,
    md.total_cast,
    cr.role_type,
    cr.role_count,
    md.cast_infos
FROM 
    MovieDetails md
LEFT JOIN 
    CastRoles cr ON md.title_id = cr.movie_id
WHERE 
    (md.total_cast > 10 OR cr.role_count IS NULL)
ORDER BY 
    md.title_rank DESC,
    md.title ASC
LIMIT 
    50;
