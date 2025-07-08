
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank,
        t.id AS movie_id
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
        AND a.name IS NOT NULL
),
KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        movie_id
),
FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_name,
        rm.company_type,
        k.keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordCount k ON rm.movie_id = k.movie_id
    WHERE 
        rm.actor_rank <= 3
)
SELECT 
    title,
    production_year,
    actor_name,
    company_type,
    COALESCE(keyword_count, 0) AS keyword_count
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    title;
