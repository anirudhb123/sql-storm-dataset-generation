WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id, 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        aka_title t
    JOIN 
        aka_name a ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
), CastCounts AS (
    SELECT 
        ct.movie_id,
        COUNT(ci.id) AS cast_count
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ct.movie_id
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
), TitleWithInfo AS (
    SELECT 
        rt.*, 
        m.info_details,
        COALESCE(cc.cast_count, 0) AS cast_count
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MovieInfo m ON rt.title_id = m.movie_id
    LEFT JOIN 
        CastCounts cc ON rt.title_id = cc.movie_id
)
SELECT 
    twi.aka_id, 
    twi.title, 
    twi.production_year, 
    twi.info_details, 
    CASE 
        WHEN twi.cast_count = 0 THEN 'No Cast' 
        ELSE 'Has Cast' 
    END AS cast_status,
    COUNT(DISTINCT mi.keyword) FILTER (WHERE mi.keyword IS NOT NULL) AS keyword_count
FROM 
    TitleWithInfo twi
LEFT JOIN 
    movie_keyword mk ON twi.title_id = mk.movie_id
LEFT JOIN 
    keyword mi ON mk.keyword_id = mi.id
WHERE 
    twi.production_year >= 2000
GROUP BY 
    twi.aka_id, twi.title, twi.production_year, twi.info_details, twi.cast_count
ORDER BY 
    twi.production_year DESC, twi.title;
