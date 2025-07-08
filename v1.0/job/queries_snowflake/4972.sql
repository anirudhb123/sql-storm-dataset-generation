
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT comp.name) AS company_count,
        LISTAGG(DISTINCT comp.name, ', ') WITHIN GROUP (ORDER BY comp.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name comp ON mc.company_id = comp.id
    GROUP BY 
        mc.movie_id
),
Keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keyword_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(ci.company_count, 0) AS company_count,
    COALESCE(ci.companies, 'None') AS companies,
    COALESCE(kw.keyword_list, 'No keywords') AS keywords,
    rm.production_year,
    CASE 
        WHEN rm.actor_rank = 1 THEN 'Top Movie'
        ELSE 'Other'
    END AS rank_label
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    Keywords kw ON rm.movie_id = kw.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    rm.actor_rank;
