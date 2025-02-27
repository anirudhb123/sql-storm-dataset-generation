WITH MovieStats AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT cn.name ORDER BY cn.name) AS company_names,
        ARRAY_AGG(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        aka_name an ON an.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        ms.title,
        ms.production_year,
        ms.cast_count,
        ms.company_names,
        ms.keywords,
        RANK() OVER (ORDER BY ms.cast_count DESC) AS cast_rank
    FROM 
        MovieStats ms
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.company_names,
    rm.keywords,
    rm.cast_rank
FROM 
    RankedMovies rm
WHERE 
    rm.cast_rank <= 10
ORDER BY 
    rm.cast_rank;
