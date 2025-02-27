WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT mc.company_id) AS num_companies,
        AVG(CASE 
            WHEN t.kind_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        kind_type t ON m.kind_id = t.id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_companies,
        avg_type,
        keywords,
        ROW_NUMBER() OVER (ORDER BY num_companies DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.num_companies,
    tm.avg_type,
    tm.keywords,
    ak.name AS actor_name,
    rp.role
FROM 
    TopMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    role_type rp ON ci.role_id = rp.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.rank;
