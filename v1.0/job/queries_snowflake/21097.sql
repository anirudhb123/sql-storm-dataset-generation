
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ' ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithCompleteInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(ca.cast_count, 0) AS cast_count,
        COALESCE(ci.company_names, 'No Companies') AS company_names
    FROM 
        title m
    LEFT JOIN 
        MovieKeywords mk ON m.id = mk.movie_id
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(*) AS cast_count
        FROM 
            cast_info
        GROUP BY 
            movie_id
    ) ca ON m.id = ca.movie_id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            LISTAGG(cn.name, ', ' ORDER BY cn.name) AS company_names
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id
        GROUP BY 
            mc.movie_id
    ) ci ON m.id = ci.movie_id
)
SELECT 
    mi.movie_id,
    mi.title,
    mi.production_year,
    mi.keywords,
    mi.cast_count,
    mi.company_names,
    RANK() OVER (ORDER BY mi.production_year DESC) AS year_rank
FROM 
    MoviesWithCompleteInfo mi
WHERE 
    mi.production_year BETWEEN 2000 AND 2020
    AND EXISTS (
        SELECT 1 
        FROM complete_cast cc 
        WHERE cc.movie_id = mi.movie_id 
        AND cc.status_id IS NULL
    )
UNION ALL
SELECT 
    rn.title_id AS movie_id,
    rn.title,
    rn.production_year,
    'No Keywords' AS keywords,
    NULL AS cast_count,
    'Unknown' AS company_names,
    RANK() OVER (ORDER BY rn.production_year DESC) AS year_rank
FROM 
    RankedTitles rn
WHERE 
    rn.rn = 1 
    AND NOT EXISTS (
        SELECT 1
        FROM MoviesWithCompleteInfo mi
        WHERE mi.movie_id = rn.title_id
    )
ORDER BY 
    year_rank, 
    production_year DESC;
