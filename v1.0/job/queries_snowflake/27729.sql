WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        a.name AS actor_name,
        p.gender
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name a ON cc.subject_id = a.person_id
    JOIN 
        name p ON a.person_id = p.imdb_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND k.keyword ILIKE '%action%'
),

movie_analytics AS (
    SELECT 
        md.title,
        md.production_year,
        COUNT(DISTINCT md.actor_name) AS actor_count,
        COUNT(DISTINCT md.company_name) AS company_count,
        COUNT(DISTINCT md.keyword) AS keyword_count
    FROM 
        movie_data md
    GROUP BY 
        md.title, md.production_year
),

final_report AS (
    SELECT 
        ma.title,
        ma.production_year,
        ma.actor_count,
        ma.company_count,
        ma.keyword_count,
        CASE 
            WHEN ma.actor_count > 5 THEN 'Diverse'
            ELSE 'Niche'
        END AS actor_diversity,
        CASE 
            WHEN ma.company_count > 3 THEN 'Major Studio'
            ELSE 'Independent'
        END AS company_type
    FROM 
        movie_analytics ma
)

SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.company_count,
    fr.keyword_count,
    fr.actor_diversity,
    fr.company_type
FROM 
    final_report fr
ORDER BY 
    fr.production_year DESC, 
    fr.actor_count DESC;
