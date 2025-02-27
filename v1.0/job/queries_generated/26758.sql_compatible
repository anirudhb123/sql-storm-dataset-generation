
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.person_role_id::text, ', ') AS cast_roles,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_info AS mi ON t.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info AS c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.cast_roles,
    md.keywords,
    cd.production_companies,
    cd.company_types,
    md.total_cast
FROM 
    MovieDetails AS md
LEFT JOIN 
    CompanyDetails AS cd ON md.movie_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title ASC
LIMIT 50;
