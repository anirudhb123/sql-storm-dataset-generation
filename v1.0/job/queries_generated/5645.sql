WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        rk.kind AS role_kind,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON ci.movie_id = at.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        role_type rk ON rk.id = ci.role_id
    WHERE 
        at.production_year > 2000
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actor_list,
        COUNT(*) AS actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_title, production_year
)
SELECT 
    ad.movie_title,
    ad.production_year,
    ad.actor_list,
    ad.actor_count,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.id) AS company_count,
    STRING_AGG(cn.name, ', ') AS company_names
FROM 
    AggregatedData ad
LEFT JOIN 
    complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = ad.movie_title AND production_year = ad.production_year LIMIT 1)
LEFT JOIN 
    movie_companies mc ON mc.movie_id = cc.movie_id
LEFT JOIN 
    company_name cn ON cn.id = mc.company_id
LEFT JOIN 
    company_type ct ON ct.id = mc.company_type_id
GROUP BY 
    ad.movie_title, ad.production_year, ct.kind
ORDER BY 
    ad.production_year DESC, ad.actor_count DESC;
