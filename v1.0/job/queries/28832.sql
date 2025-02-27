WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.kind AS company_type,
        a.name AS actor_name,
        pi.info AS person_info
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
        cast_info ca ON t.id = ca.movie_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND k.keyword LIKE '%action%'
),

AggregatedInfo AS (
    SELECT 
        md.title_id,
        md.title,
        md.production_year,
        COUNT(DISTINCT md.actor_name) AS actor_count,
        STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT md.person_info, ', ') AS all_person_info,
        STRING_AGG(DISTINCT md.company_type, ', ') AS company_types
    FROM 
        MovieDetails md
    GROUP BY 
        md.title_id, md.title, md.production_year
)

SELECT 
    a.title_id,
    a.title,
    a.production_year,
    a.actor_count,
    a.keywords,
    a.all_person_info,
    a.company_types
FROM 
    AggregatedInfo a
WHERE 
    a.actor_count > 2
ORDER BY 
    a.production_year DESC, a.actor_count DESC
LIMIT 10;
