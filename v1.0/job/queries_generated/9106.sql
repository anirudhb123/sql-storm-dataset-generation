WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aliases,
        COUNT(DISTINCT mci.company_id) AS company_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies AS mci ON t.id = mci.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aliases,
        company_count,
        RANK() OVER (ORDER BY company_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.aliases,
    tm.company_count,
    p.info AS director_info
FROM 
    TopMovies AS tm
LEFT JOIN 
    person_info AS p ON p.person_id IN (
        SELECT 
            ci.person_id 
        FROM 
            cast_info AS ci 
        JOIN 
            movie_companies AS mc ON ci.movie_id = mc.movie_id 
        WHERE 
            mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
            AND ci.movie_id = tm.movie_id
    )
WHERE 
    tm.rank <= 10;
