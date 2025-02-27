WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS production_companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast_members,
    rm.cast_names,
    cd.production_companies,
    cd.company_types,
    rm.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast_members DESC;
