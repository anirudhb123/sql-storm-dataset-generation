WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
),
MovieDetailedInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ci.person_role_id, 0) AS leading_role_id,
        ci.note AS actor_note,
        CASE 
            WHEN cc.kind IS NOT NULL THEN 'Company Exists' 
            ELSE 'No Company' 
        END AS company_status,
        rm.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
)
SELECT 
    mdi.title,
    mdi.production_year,
    mdi.leading_role_id,
    SUM(mk.keyword) FILTER (WHERE mk.keyword IS NOT NULL) AS total_keywords,
    COUNT(DISTINCT mc.company_id) AS total_companies,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    CASE 
        WHEN COUNT(DISTINCT ci.note) > 1 THEN 'Multiple Notes: ' || STRING_AGG(DISTINCT ci.note, ' | ')
        ELSE 'Single Note or No Note'
    END AS notes_summary
FROM 
    MovieDetailedInfo mdi
LEFT JOIN 
    movie_companies mc ON mdi.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mdi.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON mdi.leading_role_id = ci.id
WHERE 
    mdi.production_year > 2000
    AND mdi.keyword_count >= ALL (SELECT keyword_count FROM RankedMovies)
GROUP BY 
    mdi.movie_id, mdi.title, mdi.production_year, mdi.leading_role_id
ORDER BY 
    mdi.production_year DESC, mdi.title_rank ASC
LIMIT 100;
