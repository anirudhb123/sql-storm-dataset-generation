WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        cd.company_name,
        cd.company_type,
        cd.num_movies,
        COUNT(ci.id) FILTER (WHERE ci.note IS NOT NULL) AS cast_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN ci.nr_order END) AS avg_order
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.title_id = mc.movie_id
    LEFT JOIN 
        CompanyData cd ON mc.movie_id = cd.movie_id
    LEFT JOIN 
        cast_info ci ON rm.title_id = ci.movie_id
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = rm.title_id
    GROUP BY 
        rm.title, rm.production_year, mk.keywords, cd.company_name, cd.company_type, cd.num_movies
    HAVING 
        COUNT(ci.id) > 0
    ORDER BY 
        avg_order DESC, rm.production_year DESC
)
SELECT 
    title,
    production_year,
    keywords,
    company_name,
    company_type,
    num_movies,
    cast_count,
    avg_order
FROM 
    FinalResults
WHERE 
    production_year BETWEEN 2000 AND 2023
    AND title ILIKE '%adventure%'
    OR company_type = 'Distributor'
    OR keywords LIKE '%action%'
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 100;
