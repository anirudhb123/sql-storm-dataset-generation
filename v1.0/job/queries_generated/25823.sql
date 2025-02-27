WITH MovieRoles AS (
    SELECT 
        ct.id AS role_id,
        ct.kind AS role_name,
        ci.person_id,
        ci.movie_id,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type ct ON ci.role_id = ct.id
    GROUP BY 
        ct.id, ct.kind, ci.person_id, ci.movie_id
), RankedRoles AS (
    SELECT 
        mr.person_id,
        mr.movie_id,
        mr.role_id,
        mr.role_name,
        mr.role_count,
        ROW_NUMBER() OVER (PARTITION BY mr.movie_id ORDER BY mr.role_count DESC) AS role_rank
    FROM 
        MovieRoles mr
), MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT r.role_name || ' (' || r.role_count || ')', ', ') AS roles_summary
    FROM 
        title m
    JOIN 
        RankedRoles r ON m.id = r.movie_id
    WHERE 
        r.role_rank <= 3
    GROUP BY 
        m.id, m.title, m.production_year
), KeywordSummary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.roles_summary,
    ks.keywords
FROM 
    MovieInfo mi
LEFT JOIN 
    KeywordSummary ks ON mi.movie_id = ks.movie_id
ORDER BY 
    mi.production_year DESC, mi.title;
