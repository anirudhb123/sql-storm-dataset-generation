
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
RankedByCastCount AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    rb.movie_id,
    rb.title,
    rb.production_year,
    rb.cast_count,
    rb.cast_names,
    rb.keywords,
    m.name AS production_company,
    ct.kind AS company_type
FROM 
    RankedByCastCount rb
LEFT JOIN 
    movie_companies mc ON rb.movie_id = mc.movie_id
LEFT JOIN 
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    rb.rank <= 10
ORDER BY 
    rb.rank;  
