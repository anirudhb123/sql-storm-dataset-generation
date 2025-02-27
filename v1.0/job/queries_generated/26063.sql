WITH MovieAndCast AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        rt.role AS role,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, a.name, rt.role
),
KeywordStatistics AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        mac.movie_title,
        mac.production_year,
        mac.actor_name,
        mac.role,
        mac.company_count,
        ks.keyword_count
    FROM 
        MovieAndCast mac
    LEFT JOIN 
        KeywordStatistics ks ON mac.movie_id = ks.movie_id
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    role,
    company_count,
    COALESCE(keyword_count, 0) AS keyword_count
FROM 
    FinalResults
ORDER BY 
    production_year DESC, company_count DESC, keyword_count DESC;
