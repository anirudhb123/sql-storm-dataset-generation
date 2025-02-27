WITH MovieSummary AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies_involved
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL 
        AND ci.person_role_id IN (SELECT id FROM role_type WHERE role IN ('actor', 'actress'))
    GROUP BY 
        a.id
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_count,
        keyword_count,
        companies_involved,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC, keyword_count DESC) AS rank
    FROM 
        MovieSummary
)
SELECT 
    movie_title, 
    production_year, 
    actor_count, 
    keyword_count, 
    companies_involved,
    CASE 
        WHEN rank <= 3 THEN 'Top 3'
        ELSE 'Other'
    END AS rank_category
FROM 
    RankedMovies
WHERE 
    production_year BETWEEN 2000 AND 2023
ORDER BY 
    production_year DESC, 
    rank;
