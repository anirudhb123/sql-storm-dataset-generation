WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title, 
        ak.name AS actor_name, 
        COUNT(DISTINCT mck.keyword_id) AS keyword_count,
        ct.kind AS company_type,
        MIN(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS release_date
    FROM 
        aka_title AS a
    JOIN 
        complete_cast AS cc ON a.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        movie_keyword AS mck ON a.id = mck.movie_id
    JOIN 
        movie_companies AS mc ON a.id = mc.movie_id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info AS mi ON a.id = mi.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, ak.name, ct.kind
),
Benchmark AS (
    SELECT 
        movie_title, 
        actor_name, 
        keyword_count, 
        company_type, 
        release_date,
        ROW_NUMBER() OVER (PARTITION BY company_type ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title, 
    actor_name, 
    keyword_count, 
    company_type, 
    release_date
FROM 
    Benchmark
WHERE 
    rank <= 5
ORDER BY 
    company_type, keyword_count DESC;
