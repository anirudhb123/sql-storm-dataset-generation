
WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank,
        MAX(mw.info) AS movie_info,
        a.movie_id
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info mw ON a.movie_id = mw.movie_id AND mw.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
    GROUP BY 
        a.title, a.production_year, a.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        ct.kind AS role,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        cast_info ci 
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id, ct.kind
),
TitlesWithCast AS (
    SELECT 
        rt.title,
        rt.production_year,
        cd.role,
        cd.total_cast
    FROM 
        RankedTitles rt
    JOIN 
        CastDetails cd ON rt.movie_id = cd.movie_id
)
SELECT 
    twc.title,
    twc.production_year,
    twc.role,
    twc.total_cast,
    CASE 
        WHEN twc.total_cast IS NULL THEN 'No Cast Info'
        ELSE CAST(twc.total_cast AS VARCHAR)
    END AS cast_info
FROM 
    TitlesWithCast twc
WHERE 
    twc.production_year >= 2000
ORDER BY 
    twc.production_year DESC, 
    twc.title ASC
LIMIT 50;
