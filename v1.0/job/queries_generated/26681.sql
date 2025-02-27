WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id AS movie_kind_id,
        GROUP_CONCAT(DISTINCT ak.name) AS alternate_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (
            SELECT ci.person_id 
            FROM cast_info ci 
            WHERE ci.movie_id = t.id
        )
    GROUP BY 
        t.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        md.movie_title,
        md.production_year,
        cd.companies,
        cd.company_types,
        md.keywords,
        md.movie_kind_id
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyDetails cd ON md.id = cd.movie_id
)
SELECT 
    cm.movie_title,
    cm.production_year,
    cm.companies,
    cm.company_types,
    cm.keywords,
    kt.kind as movie_kind
FROM 
    CompleteMovieInfo cm
JOIN 
    kind_type kt ON cm.movie_kind_id = kt.id
WHERE 
    cm.production_year >= 2000
ORDER BY 
    cm.production_year DESC, 
    cm.movie_title ASC;
