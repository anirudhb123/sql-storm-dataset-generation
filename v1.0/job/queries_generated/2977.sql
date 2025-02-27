WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvseries'))
),
CompanyInfo AS (
    SELECT 
        c.name AS company_name,
        CASE 
            WHEN km.keyword IS NOT NULL THEN km.keyword 
            ELSE 'No Keywords' 
        END AS keyword_info
    FROM 
        company_name c
    LEFT JOIN 
        movie_companies mc ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        c.country_code IS NOT NULL
),
TitleCast AS (
    SELECT 
        t.title AS movie_title,
        ak.name AS actor_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ci.nr_order) AS cast_rank
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year > 2000
)
SELECT 
    rm.title,
    rm.production_year,
    ci.company_name,
    ci.keyword_info,
    tc.actor_name,
    tc.cast_rank
FROM 
    RankedMovies rm
JOIN 
    CompanyInfo ci ON ci.keyword_info NOT LIKE 'No Keywords'
LEFT JOIN 
    TitleCast tc ON tc.movie_title = rm.title
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, 
    tc.cast_rank ASC;
