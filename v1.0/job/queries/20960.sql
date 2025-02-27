WITH RankedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC, at.title ASC) AS title_rank,
        kt.keyword
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        at.production_year IS NOT NULL
        AND (kt.keyword IS NULL OR kt.keyword LIKE '%action%')
),
PersonRoleCounts AS (
    SELECT  
        ci.role_id,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    WHERE 
        ci.note IS NOT NULL AND ci.note <> ''
    GROUP BY 
        ci.role_id
),
MoviesWithRoleCounts AS (
    SELECT 
        at.title,
        at.production_year,
        prc.role_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY prc.role_count DESC) AS role_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    LEFT JOIN 
        PersonRoleCounts prc ON ci.role_id = prc.role_id
    WHERE 
        (at.production_year > 2000 AND at.production_year <= 2023)
    GROUP BY 
        at.id, at.title, at.production_year, prc.role_count
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
),
FinalResults AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(r.title_rank, 0) AS title_rank,
        COALESCE(m.role_count, 0) AS role_count
    FROM 
        MoviesWithRoleCounts m
    LEFT JOIN 
        RankedTitles r ON m.title = r.title AND m.production_year = r.production_year
)
SELECT 
    title,
    production_year,
    title_rank,
    role_count,
    CASE 
        WHEN title_rank < 3 THEN 'Top'
        WHEN title_rank BETWEEN 3 AND 10 THEN 'Mid Tier'
        ELSE 'Low'
    END AS title_classification,
    CONCAT('Year: ', production_year, ', Roles: ', role_count) AS details
FROM 
    FinalResults
WHERE 
    title IS NOT NULL
ORDER BY 
    production_year DESC, title_rank, role_count DESC
LIMIT 50;
