WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS role,
        COUNT(DISTINCT mc.company_id) AS company_count,
        MAX(mk.keyword) AS most_frequent_keyword
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        cast_info ci ON ci.id = cc.subject_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type rt ON rt.id = ci.role_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        comp_cast_type ct ON ct.id = ci.person_role_id
    WHERE 
        t.production_year >= 2000
        AND (t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%'))
        AND a.name IS NOT NULL
    GROUP BY 
        t.title, t.production_year, a.name, ct.kind
),
RankedMovies AS (
    SELECT 
        title,
        production_year,
        actor_name,
        role,
        company_count,
        most_frequent_keyword,
        RANK() OVER (PARTITION BY production_year ORDER BY company_count DESC) AS rank_within_year
    FROM 
        MovieDetails
)
SELECT 
    production_year,
    title,
    actor_name,
    role,
    company_count,
    most_frequent_keyword,
    CASE 
        WHEN company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_status
FROM 
    RankedMovies
WHERE 
    rank_within_year <= 5
ORDER BY 
    production_year DESC, company_count DESC;
