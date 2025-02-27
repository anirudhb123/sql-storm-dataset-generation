
WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT ak.name, ',') AS aka_names,
        STRING_AGG(DISTINCT cn.name, ',') AS company_names,
        STRING_AGG(DISTINCT kw.keyword, ',') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON mt.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        STRING_AGG(DISTINCT pi.info, ',') AS personal_info
    FROM 
        name p
    LEFT JOIN 
        person_info pi ON p.imdb_id = pi.person_id
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    pd.name AS person_name,
    pd.personal_info,
    md.aka_names,
    md.company_names,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    PersonDetails pd ON cc.subject_id = pd.person_id
ORDER BY 
    md.production_year DESC, md.title;
