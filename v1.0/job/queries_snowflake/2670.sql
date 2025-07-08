
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
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
    COALESCE(ci.company_name, 'Independent') AS company_name,
    COALESCE(ci.company_type, 'N/A') AS company_type,
    tk.keywords,
    COUNT(DISTINCT c.person_id) AS total_actors
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    TitleKeywords tk ON rm.movie_id = tk.movie_id
LEFT JOIN 
    cast_info c ON rm.movie_id = c.movie_id
WHERE 
    rm.rank <= 5
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ci.company_name, ci.company_type, tk.keywords
ORDER BY 
    rm.production_year DESC, total_actors DESC;
