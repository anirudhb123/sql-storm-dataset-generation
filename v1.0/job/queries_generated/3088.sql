WITH RankedTitles AS (
    SELECT 
        t.id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_info
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
    WHERE 
        it.info ILIKE '%award%'
    GROUP BY 
        m.movie_id
),
CastRoles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        COUNT(c.person_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id, c.role_id
    HAVING 
        COUNT(c.person_id) >= 2
),
CombinedResults AS (
    SELECT 
        r.title,
        r.production_year,
        mi.movie_info,
        COALESCE(cr.role_count, 0) AS role_count
    FROM 
        RankedTitles r
    LEFT JOIN 
        MovieInfo mi ON r.id = mi.movie_id
    LEFT JOIN 
        CastRoles cr ON r.id = cr.movie_id
)
SELECT 
    title,
    production_year,
    movie_info,
    role_count
FROM 
    CombinedResults
WHERE 
    role_count > 0 OR movie_info IS NOT NULL
ORDER BY 
    production_year DESC, title ASC;
