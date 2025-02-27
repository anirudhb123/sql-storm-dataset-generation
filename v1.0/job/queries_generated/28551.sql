WITH MovieData AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.role_id::text, ', ') AS role_ids,
        STRING_AGG(DISTINCT ci.note, ', ') AS cast_notes
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
        AND (LOWER(t.title) LIKE '%action%' OR LOWER(t.title) LIKE '%adventure%')
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
        STRING_AGG(DISTINCT m.note, ', ') AS movie_notes
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    JOIN 
        movie_info AS m ON mc.movie_id = m.movie_id
    WHERE 
        m.info_type_id = (SELECT id FROM info_type WHERE info='Budget') 
        AND m.info LIKE '%Million%'
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    cd.company_names,
    cd.company_types,
    cd.movie_notes,
    md.role_ids,
    md.cast_notes
FROM 
    MovieData AS md
LEFT JOIN 
    CompanyData AS cd ON md.movie_title = cd.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
