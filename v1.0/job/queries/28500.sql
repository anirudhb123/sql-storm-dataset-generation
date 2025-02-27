
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names,
        k.keyword AS main_keyword
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, k.keyword
),
GenreRanking AS (
    SELECT 
        rt.role AS role_type,
        COUNT(DISTINCT rc.person_id) AS role_count
    FROM 
        role_type rt
    LEFT JOIN 
        cast_info rc ON rt.id = rc.role_id
    GROUP BY 
        rt.role
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.company_names,
    rm.main_keyword,
    gr.role_count
FROM 
    RankedMovies rm
LEFT JOIN 
    GenreRanking gr ON rm.cast_count = gr.role_count
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
