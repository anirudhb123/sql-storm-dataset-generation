
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_by_year
    FROM 
        aka_title t
    JOIN 
        aka_name a ON t.movie_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(kr.keywords, 'N/A') AS keywords,
        COALESCE(cr.role_details, 'N/A') AS role_details
    FROM 
        title t
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) kr ON t.id = kr.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            LISTAGG(DISTINCT CONCAT(role, ': ', role_count), '; ') WITHIN GROUP (ORDER BY role) AS role_details
        FROM 
            CastRoles
        GROUP BY 
            movie_id
    ) cr ON t.id = cr.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    rt.aka_name,
    rt.rank_by_year,
    md.keywords,
    md.role_details
FROM 
    MovieDetails md
JOIN 
    RankedTitles rt ON md.movie_id = rt.title_id
WHERE 
    rt.rank_by_year <= 5
ORDER BY 
    md.production_year DESC, 
    rt.rank_by_year;
