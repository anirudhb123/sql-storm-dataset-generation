WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        count(ki.keyword) AS keyword_count,
        array_agg(DISTINCT cn.name) AS company_names,
        array_agg(DISTINCT ak.name) AS actor_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY count(ki.keyword) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword ki ON mk.keyword_id = ki.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword_count,
    rm.company_names,
    rm.actor_names
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year, rm.keyword_count DESC;
