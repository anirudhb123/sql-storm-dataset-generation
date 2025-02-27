WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        aka_title t
    WHERE 
        t.title IS NOT NULL
),
FilteredActors AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 2
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        k.keyword
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    WHERE 
        k.phonetic_code IS NOT NULL
),
CompanyProduction AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code = 'USA'
)
SELECT 
    r.movie_id,
    r.movie_title,
    r.production_year,
    fa.actor_name,
    fa.movie_count,
    mk.keyword,
    cp.company_name,
    cp.company_type
FROM 
    RankedMovies r
JOIN 
    FilteredActors fa ON r.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = fa.person_id)
JOIN 
    MovieKeywords mk ON r.movie_id = mk.movie_id
JOIN 
    CompanyProduction cp ON r.movie_id = cp.movie_id
WHERE 
    r.rank <= 10
ORDER BY 
    r.production_year DESC, 
    r.movie_title;
