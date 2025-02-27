WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id) AS title_rank,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
TopTitles AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        rt.actors
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_rank <= 5
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, '; ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        mc.movie_id
),
TitleWithCompanies AS (
    SELECT 
        tt.title,
        tt.production_year,
        mc.company_count,
        mc.company_names
    FROM 
        TopTitles tt
    LEFT JOIN 
        MovieCompanies mc ON mc.movie_id = tt.title_id
)
SELECT 
    twc.title,
    twc.production_year,
    COALESCE(twc.company_count, 0) AS company_count,
    COALESCE(twc.company_names, 'No Companies') AS company_names,
    (
        SELECT 
            COUNT(DISTINCT mi.info_type_id)
        FROM 
            movie_info mi
        WHERE 
            mi.movie_id = twc.title_id
    ) AS info_type_count,
    (
        SELECT 
            COUNT(DISTINCT mk.keyword) 
        FROM 
            movie_keyword mk 
        JOIN 
            keyword k ON k.id = mk.keyword_id 
        WHERE 
            mk.movie_id = twc.title_id 
        AND 
            k.phonetic_code IS NOT NULL
    ) AS keyword_count
FROM 
    TitleWithCompanies twc
WHERE 
    twc.production_year >= 2000
ORDER BY 
    twc.production_year DESC,
    twc.title ASC
LIMIT 10;
