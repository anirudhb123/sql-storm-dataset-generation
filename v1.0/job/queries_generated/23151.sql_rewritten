WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS avg_note_present,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL 
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.id) AS company_count
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
    rm.title,
    rm.production_year,
    COALESCE(cd.company_name, 'Not Associated') AS company_name,
    rm.cast_count,
    rm.avg_note_present,
    CASE 
        WHEN rm.production_year < 2000 THEN 'Classic'
        WHEN rm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords 
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rm.rn <= 5 
GROUP BY 
    rm.title, rm.production_year, cd.company_name, rm.cast_count, rm.avg_note_present
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;