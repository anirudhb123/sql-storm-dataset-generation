WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.person_id) AS unique_cast_count
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        c.cast_count,
        ci.company_name,
        ci.company_type,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC) AS rank
    FROM 
        MovieDetails md
    JOIN 
        CompleteCast c ON md.movie_id = c.movie_id
    LEFT JOIN 
        CompanyInfo ci ON md.movie_id = ci.movie_id
)
SELECT 
    title,
    production_year,
    keyword,
    cast_count,
    company_name,
    company_type
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, title;
