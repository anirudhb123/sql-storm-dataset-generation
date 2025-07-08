
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aliases,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS companies,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC, m.title ASC) AS rank
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name AS co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast AS cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ca ON cc.subject_id = ca.person_id
    LEFT JOIN 
        aka_name AS ak ON ca.person_id = ak.person_id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    rank,
    title,
    production_year,
    cast_count,
    aliases,
    companies,
    keywords
FROM 
    RankedMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, 
    title ASC;
