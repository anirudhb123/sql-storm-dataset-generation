WITH RankedTitles AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    INNER JOIN 
        aka_title at ON t.id = at.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, ci.person_id, rt.role
),
TitleWithKeyword AS (
    SELECT 
        mt.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    r.title,
    r.production_year,
    kt.keywords,
    c.person_id,
    COALESCE(cr.role_count, 0) AS role_count
FROM 
    RankedTitles r
LEFT JOIN 
    CastWithRoles c ON r.id = c.movie_id
LEFT JOIN 
    TitleWithKeyword kt ON kt.movie_id = r.id
LEFT JOIN 
    (SELECT movie_id, person_id, COUNT(*) AS role_count
     FROM cast_info
     GROUP BY movie_id, person_id) cr ON cr.movie_id = c.movie_id AND cr.person_id = c.person_id
WHERE 
    r.rank <= 5
ORDER BY 
    r.production_year DESC, r.title;
