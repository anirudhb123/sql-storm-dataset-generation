WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        concat(cn.name, ' (', ct.kind, ')') AS company_details,
        k.keyword AS keywords,
        array_agg(DISTINCT ka.name) AS aka_names,
        array_agg(DISTINCT p.info) AS person_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    GROUP BY 
        t.id, cn.name, ct.kind, k.keyword, t.production_year
),
Ranking AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_details,
        md.keywords,
        md.aka_names,
        md.person_info,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.production_year DESC) AS rank_by_year
    FROM 
        MovieDetails md
)
SELECT 
    rank_by_year,
    movie_title,
    production_year,
    company_details,
    keywords,
    aka_names,
    person_info
FROM 
    Ranking
WHERE 
    rank_by_year <= 10
ORDER BY 
    production_year DESC, rank_by_year;
