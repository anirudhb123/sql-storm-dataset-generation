WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.country_code) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    fc.company_name,
    fc.company_type,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(ci.id) AS cast_count,
    MIN(ci.nr_order) AS first_apparition_order
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCompanies fc ON rm.movie_id = fc.movie_id AND fc.company_rank = 1
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_by_title = 1
    AND (rm.production_year > 2000 OR rm.production_year IS NULL)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, fc.company_name, fc.company_type, mk.keywords
HAVING 
    COUNT(ci.id) > 0
ORDER BY 
    rm.production_year DESC, rm.title ASC;
