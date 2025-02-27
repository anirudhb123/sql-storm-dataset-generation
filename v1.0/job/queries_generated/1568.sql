WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
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
)
SELECT 
    rm.title, 
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(ci.company_name, 'No company') AS production_company,
    COUNT(ci.company_name) OVER (PARTITION BY rm.movie_id) AS company_count,
    c.gender,
    (SELECT 
        COUNT(*) 
     FROM 
        cast_info 
     WHERE 
        movie_id = rm.movie_id 
        AND person_role_id IN (SELECT id FROM role_type WHERE role LIKE 'actor%')) AS actor_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    cast_info ci2 ON rm.movie_id = ci2.movie_id
LEFT JOIN 
    name n ON ci2.person_id = n.imdb_id
LEFT JOIN 
    aka_name an ON n.imdb_id = an.person_id AND an.name IS NOT NULL
WHERE 
    rm.title IS NOT NULL 
    AND rm.title_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
