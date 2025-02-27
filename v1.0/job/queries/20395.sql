WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.id) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code = 'USA'
),
ActorDetails AS (
    SELECT 
        ka.person_id,
        ka.name,
        COUNT(ci.id) AS movie_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM 
        aka_name ka
    LEFT JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    GROUP BY 
        ka.person_id, ka.name
    HAVING 
        COUNT(ci.id) > 2
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
    rm.title,
    rm.production_year,
    COUNT(DISTINCT fc.company_name) AS company_count,
    ak.name AS actor_name,
    ak.movie_count,
    ak.has_note_ratio,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredCompanies fc ON rm.movie_id = fc.movie_id
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    ActorDetails ak ON ci.person_id = ak.person_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 5 
    AND (ak.has_note_ratio IS NULL OR ak.has_note_ratio > 0.5)
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ak.name, ak.movie_count, ak.has_note_ratio, mk.keywords
ORDER BY 
    rm.production_year DESC, company_count DESC, ak.name;
