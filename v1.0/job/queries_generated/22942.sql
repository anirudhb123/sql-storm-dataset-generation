WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FullCast AS (
    SELECT 
        cm.company_name AS production_company,
        t.title AS movie_title,
        p.name AS person_name,
        p.gender,
        ROW_NUMBER() OVER (PARTITION BY cm.company_name ORDER BY t.production_year DESC) AS rank_by_company
    FROM 
        movie_companies mc
    JOIN 
        company_name cm ON mc.company_id = cm.id
    JOIN 
        aka_title t ON mc.movie_id = t.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        cm.country_code IS NOT NULL
),
UniqueKeywords AS (
    SELECT DISTINCT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        COUNT(uk.keyword) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        UniqueKeywords uk ON rm.movie_id = uk.movie_id
    WHERE 
        rm.rank_by_cast <= 5
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year
)
SELECT 
    fm.movie_title,
    fm.production_year,
    COALESCE(fc.production_company, 'Independent') AS production_company,
    fc.person_name,
    fm.keyword_count,
    CASE 
        WHEN fc.gender = 'F' THEN 'Female Lead'
        WHEN fc.gender = 'M' THEN 'Male Lead'
        ELSE 'Unknown Lead'
    END AS lead_type
FROM 
    FilteredMovies fm
LEFT JOIN 
    FullCast fc ON fm.movie_title = fc.movie_title AND fc.rank_by_company <= 3
WHERE 
    (fm.keyword_count > 0) OR (fm.production_year IS NULL)
ORDER BY 
    fm.production_year DESC, 
    fm.keyword_count DESC, 
    fm.movie_title;
