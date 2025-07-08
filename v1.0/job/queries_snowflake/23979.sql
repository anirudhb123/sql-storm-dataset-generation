
WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.id) DESC) AS year_rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
NotableNames AS (
    SELECT 
        an.name,
        COUNT(DISTINCT ci.movie_id) AS movie_appearance_count
    FROM 
        aka_name an
    JOIN 
        cast_info ci ON an.person_id = ci.person_id
    WHERE 
        an.name IS NOT NULL
    GROUP BY 
        an.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rm.title_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    nn.name AS noteworthy_actor,
    cd.company_name,
    cd.company_type,
    cd.company_count,
    (CASE WHEN cd.company_count > 1 THEN 'Multiple Companies' ELSE 'Single Company' END) AS company_status,
    (SELECT LISTAGG(DISTINCT mm.keyword, ', ') 
     FROM movie_keyword mk
     JOIN keyword mm ON mk.keyword_id = mm.id
     WHERE mk.movie_id = rm.title_id) AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    NotableNames nn ON nn.movie_appearance_count = (SELECT MAX(cast_count) FROM RankedMovies WHERE production_year = rm.production_year)
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = rm.title_id
WHERE 
    rm.year_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC
LIMIT 10;
