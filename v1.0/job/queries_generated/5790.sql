WITH RankedMovies AS (
    SELECT 
        a.title,
        t.production_year,
        c.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.title) AS rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    JOIN 
        cast_info ci ON a.movie_id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
) 
SELECT 
    rm.title,
    rm.production_year,
    cd.company_name,
    cd.company_type,
    cd.keyword_count,
    COUNT(DISTINCT rm.person_id) AS actor_count
FROM 
    RankedMovies rm
JOIN 
    CompanyDetails cd ON rm.rank = 1
GROUP BY 
    rm.title, rm.production_year, cd.company_name, cd.company_type, cd.keyword_count
ORDER BY 
    rm.production_year DESC, actor_count DESC
LIMIT 50;
