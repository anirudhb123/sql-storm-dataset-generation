WITH recent_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        c.kind AS company_kind,
        k.keyword,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        COUNT(DISTINCT pi.id) AS info_count
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.movie_id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id
    LEFT JOIN 
        info_type pi ON mi.info_type_id = pi.id
    WHERE 
        a.production_year >= 2020
    GROUP BY 
        a.id, a.title, a.production_year, c.kind, k.keyword
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_kind,
    rm.keyword,
    rm.cast_count,
    rm.info_count
FROM 
    recent_movies rm
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
LIMIT 50;
