WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
EligibleMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank = 1 AND rm.keyword_count > 5
)
SELECT 
    em.title,
    em.production_year,
    a.name AS actor_name,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    EligibleMovies em
JOIN 
    complete_cast cc ON em.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON em.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    em.production_year > 2000
GROUP BY 
    em.title, em.production_year, a.name, ct.kind
ORDER BY 
    company_count DESC, em.production_year ASC;
