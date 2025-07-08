
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        cn.country_code = 'USA' AND 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, 
        t.title, 
        t.production_year
), 
RankedByCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        ROW_NUMBER() OVER (ORDER BY rm.total_cast DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    rb.movie_id,
    rb.title,
    rb.production_year,
    rb.total_cast,
    rb.rank
FROM 
    RankedByCast rb
WHERE 
    rb.rank <= 10
ORDER BY 
    rb.rank;
