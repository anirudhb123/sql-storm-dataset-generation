WITH MovieDetails AS (
    SELECT
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        r.role AS actor_role,
        p.name AS person_name,
        COUNT(DISTINCT kc.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS row_num
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name p ON p.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, r.role, p.name
),
Reputation AS (
    SELECT
        t.id AS movie_id,
        COUNT(DISTINCT ci.person_id) AS reputable_actors,
        AVG(CASE WHEN mc.company_type_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_company_reputation
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
FinalResults AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.company_name,
        md.actor_role,
        md.person_name,
        md.actor_count,
        r.reputable_actors,
        r.avg_company_reputation
    FROM 
        MovieDetails md
    LEFT JOIN 
        Reputation r ON md.row_num = 1 AND r.movie_id = md.row_num
    WHERE 
        md.actor_count > 1 
        AND (md.production_year IS NULL OR md.production_year > 2000)
        AND (md.movie_keyword LIKE 'Action%' OR md.movie_keyword IS NULL)
        AND (md.company_name IS NOT NULL OR EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = md.movie_title LIMIT 1))
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    company_name,
    actor_role,
    person_name,
    actor_count,
    reputable_actors,
    avg_company_reputation
FROM 
    FinalResults
WHERE 
    actor_count > 2 OR reputable_actors > 5
ORDER BY 
    production_year DESC, actor_count DESC
LIMIT 50;
