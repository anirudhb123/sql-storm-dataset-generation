
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        LISTAGG(CONCAT(a.name, ' as ', rt.role), ', ') WITHIN GROUP (ORDER BY ci.nr_order) AS cast_roles,
        COUNT(*) AS total_cast
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS company_info
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_info mi ON mc.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%awards%')
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cw.cast_roles,
    COALESCE(mi.company_info, 'No Info Available') AS company_info,
    rt.keywords,
    CASE 
        WHEN rt.rn = 1 THEN 'Latest in Kind'
        ELSE 'Prior Titles'
    END AS title_status
FROM 
    RankedTitles rt
LEFT JOIN 
    CastWithRoles cw ON rt.title_id = cw.movie_id
LEFT JOIN 
    MovieInfo mi ON rt.title_id = mi.movie_id
WHERE 
    (cw.total_cast > 0 OR cw.total_cast IS NULL) 
    AND rt.production_year >= (SELECT MAX(production_year) - 10 FROM aka_title)
ORDER BY 
    rt.production_year DESC, rt.title;
