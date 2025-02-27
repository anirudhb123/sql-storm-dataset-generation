WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
KeywordCount AS (
    SELECT 
        mv.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        (SELECT DISTINCT movie_id FROM title WHERE production_year BETWEEN 2000 AND 2020) mv ON mk.movie_id = mv.movie_id
    GROUP BY 
        mv.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_name,
    kc.keyword_count,
    cd.company_name,
    cd.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordCount kc ON rm.id = kc.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.id = cd.movie_id
WHERE 
    rm.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.title;
