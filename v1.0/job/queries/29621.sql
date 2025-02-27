WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id, 
        a.title AS movie_title, 
        a.production_year, 
        a.kind_id,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_members,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title a
    LEFT JOIN cast_info ci ON a.id = ci.movie_id
    LEFT JOIN aka_name c ON ci.person_id = c.person_id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY a.id, a.title, a.production_year, a.kind_id
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id
)

SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.kind_id,
    md.cast_members,
    cd.companies,
    cd.company_types,
    (SELECT STRING_AGG(DISTINCT i.info, ', ') 
     FROM movie_info mi 
     JOIN info_type i ON mi.info_type_id = i.id 
     WHERE mi.movie_id = md.movie_id) AS additional_info
FROM MovieDetails md
LEFT JOIN CompanyDetails cd ON md.movie_id = cd.movie_id
WHERE md.production_year BETWEEN 2000 AND 2020
ORDER BY md.production_year DESC, md.movie_title;

