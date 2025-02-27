WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        ARRAY_AGG(DISTINCT p.info) AS person_infos
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind
),
KeywordAggregation AS (
    SELECT 
        title_id,
        STRING_AGG(DISTINCT keyword, ', ') AS aggregated_keywords
    FROM 
        MovieDetails
    GROUP BY 
        title_id
),
FinalReport AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        k.aggregated_keywords,
        md.company_type,
        md.actor_names,
        md.person_infos
    FROM 
        MovieDetails md
    JOIN 
        KeywordAggregation k ON md.title_id = k.title_id
    ORDER BY 
        md.production_year DESC, 
        md.title
)
SELECT 
    title_id,
    title,
    production_year,
    aggregated_keywords,
    company_type,
    actor_names,
    person_infos
FROM 
    FinalReport
LIMIT 100;