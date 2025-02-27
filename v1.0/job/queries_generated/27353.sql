WITH MovieCharacterCounts AS (
    SELECT 
        a.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS character_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        a.title
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mt.movie_title,
    mk.keywords,
    mc.companies,
    m.character_count
FROM 
    MovieCharacterCounts m
JOIN 
    aka_title mt ON mt.title = m.movie_title
LEFT JOIN 
    MovieKeywords mk ON mt.id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON mt.id = mc.movie_id
WHERE 
    mt.production_year >= 2000
ORDER BY 
    m.character_count DESC, 
    mt.movie_title;
