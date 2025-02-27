WITH RecursiveNameCTE AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name,
        a.md5sum,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY a.id) AS rn
    FROM 
        aka_name a
    WHERE 
        a.name IS NOT NULL
),
TopNTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
    HAVING 
        COUNT(mk.keyword_id) > 10
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(aa.name, ', ') AS actor_names,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        RecursiveNameCTE aa ON ci.person_id = aa.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfoWithRoles AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ct.kind AS company_type,
        CASE 
            WHEN cc.actor_count > 0 THEN 'Has Cast'
            ELSE 'No Cast'
        END AS cast_status
    FROM 
        aka_title m
    LEFT JOIN 
        MovieCompanies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        CastDetails cc ON m.id = cc.movie_id
    WHERE 
        ct.kind IS NOT NULL OR 
        (ct.kind IS NULL AND m.id IN (SELECT DISTINCT movie_id FROM cast_info))
),
FinalResults AS (
    SELECT 
        t.movie_id,
        t.title,
        t.production_year,
        t.company_type,
        t.cast_status,
        COUNT(mi.info) AS info_count
    FROM 
        MovieInfoWithRoles t
    LEFT JOIN 
        movie_info mi ON t.movie_id = mi.movie_id
    GROUP BY 
        t.movie_id, t.title, t.production_year, t.company_type, t.cast_status
    HAVING 
        COUNT(mi.info) > 0
    ORDER BY 
        t.production_year DESC, info_count DESC
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.company_type,
    f.cast_status,
    COALESCE(f.info_count, 0) AS total_info
FROM 
    FinalResults f
UNION ALL
SELECT 
    NULL AS movie_id,
    'Total Movies' AS title,
    COUNT(DISTINCT movie_id) AS production_year,
    NULL AS company_type,
    NULL AS cast_status,
    COUNT(*) AS total_info
FROM 
    FinalResults;
