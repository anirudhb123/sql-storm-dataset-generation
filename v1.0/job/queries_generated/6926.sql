WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighCastMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5
),
TopCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
Result AS (
    SELECT 
        h.title, 
        h.production_year, 
        h.cast_count, 
        tc.company_name, 
        tc.company_type
    FROM 
        HighCastMovies h
    LEFT JOIN 
        TopCompanies tc ON h.movie_id = tc.movie_id
)
SELECT 
    title,
    production_year,
    cast_count,
    STRING_AGG(company_name || ' (' || company_type || ')', ', ') AS companies
FROM 
    Result
GROUP BY 
    title, production_year, cast_count
ORDER BY 
    cast_count DESC, title;
