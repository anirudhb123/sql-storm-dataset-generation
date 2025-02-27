
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT mc.company_id) AS number_of_companies,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        MAX(CASE 
            WHEN ci.note IS NOT NULL AND ci.note LIKE '%Featured%' THEN 1 
            ELSE 0 
        END) AS featured_role
    FROM 
        movie_companies mc
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        cc.movie_id
),
KeywordsByMovie AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.title,
    r.production_year,
    COALESCE(m.number_of_companies, 0) AS number_of_companies,
    COALESCE(k.keyword_count, 0) AS keyword_count,
    CASE WHEN COALESCE(m.featured_role, 0) = 1 THEN 'Yes' ELSE 'No' END AS has_featured_role,
    CASE 
        WHEN COALESCE(m.number_of_companies, 0) > 0 THEN 
            CASE 
                WHEN COALESCE(k.keyword_count, 0) > 10 THEN 'High Keyword Density'
                WHEN COALESCE(k.keyword_count, 0) BETWEEN 5 AND 10 THEN 'Average Keyword Density'
                ELSE 'Low Keyword Density'
            END 
        ELSE 'No Companies'
    END AS company_keyword_density
FROM 
    RankedTitles r
LEFT JOIN 
    MovieDetails m ON r.title_id = m.movie_id
LEFT JOIN 
    KeywordsByMovie k ON r.title_id = k.movie_id
WHERE 
    r.rank_within_year <= 5 
    AND (m.number_of_companies IS NULL OR m.number_of_companies > 2) 
ORDER BY 
    r.production_year DESC, 
    m.number_of_companies DESC,
    k.keyword_count DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
