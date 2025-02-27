WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COALESCE(SUM(ci.nr_order), 0) AS total_cast
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id
),
PersonDetails AS (
    SELECT 
        ak.name AS aka_name,
        p.id AS person_id,
        pi.info AS person_info
    FROM 
        aka_name ak
    JOIN 
        name n ON ak.person_id = n.id
    JOIN 
        person_info pi ON n.imdb_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate')
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.companies,
    md.total_cast,
    pd.aka_name,
    pd.person_info
FROM 
    MovieDetails md
LEFT JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
LEFT JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.title ASC
LIMIT 50;
