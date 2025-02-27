WITH RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
), 

CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(DISTINCT ci.person_id) AS num_actors
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, r.role
), 

MovieDetailedInfo AS (
    SELECT 
        a.title_id,
        a.title,
        a.production_year,
        coalesce(k.keyword, 'No Keywords') AS keyword,
        cr.role AS cast_role,
        cr.num_actors,
        COALESCE(SUM(mk.info) FILTER (WHERE mi.info_type_id = 1), 'No Info') AS tagline_info
    FROM 
        RecursiveTitleCTE a
    LEFT JOIN 
        movie_keyword mk ON a.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        CastRoles cr ON a.title_id = cr.movie_id
    LEFT JOIN 
        movie_info mi ON a.title_id = mi.movie_id
    GROUP BY 
        a.title_id, a.title, a.production_year, k.keyword, cr.role, cr.num_actors
)

SELECT 
    m.title,
    m.production_year,
    m.keyword,
    m.cast_role,
    m.num_actors,
    CASE 
        WHEN m.num_actors IS NULL THEN 'No Cast'
        WHEN m.num_actors > 5 THEN 'Large Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN m.tagline_info IS NULL THEN 'No Tagline'
        ELSE m.tagline_info
    END AS tagline_description
FROM 
    MovieDetailedInfo m
WHERE 
    m.kind_id IN (
        SELECT 
            kt.id 
        FROM 
            kind_type kt
        WHERE 
            kt.kind = 'Feature'
    )
AND 
    (m.production_year BETWEEN 2000 AND 2023 OR m.production_year IS NULL)
ORDER BY 
    m.production_year DESC, 
    m.num_actors DESC NULLS LAST;
