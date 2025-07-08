WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS num_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.num_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
)
SELECT 
    f.title,
    f.production_year,
    f.num_cast,
    COALESCE(kw.keyword, 'No Keywords') AS keyword,
    co.name AS company_name,
    pi.info AS person_info
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    complete_cast cc ON f.movie_id = cc.movie_id
LEFT JOIN 
    person_info pi ON cc.subject_id = pi.person_id
WHERE 
    f.production_year IS NOT NULL 
    AND f.num_cast > 1
    AND (pi.info IS NULL OR pi.info LIKE '%lead%')
ORDER BY 
    f.production_year DESC, f.num_cast DESC;
