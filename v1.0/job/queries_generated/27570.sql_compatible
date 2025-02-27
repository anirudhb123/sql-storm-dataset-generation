
WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        aka_title ak_t ON t.id = ak_t.movie_id
    LEFT JOIN 
        aka_name ak ON ak_t.id = ak.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        c.movie_id
),
CompanyInfo AS (
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
    mt.title,
    mt.production_year,
    mt.aka_names,
    mt.keywords,
    cd.total_cast,
    cd.cast_names,
    ci.production_companies,
    ci.company_types
FROM 
    MovieTitles mt
LEFT JOIN 
    CastDetails cd ON mt.title_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON mt.title_id = ci.movie_id
ORDER BY 
    mt.production_year DESC, 
    mt.title;
