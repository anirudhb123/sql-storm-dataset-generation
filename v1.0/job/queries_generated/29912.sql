WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.cast_count,
    mc.company_names,
    mc.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    MovieCompanies mc ON md.movie_id = mc.movie_id
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
