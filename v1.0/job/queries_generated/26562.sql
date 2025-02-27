WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_casts,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title_id, title, production_year, total_casts, actor_names,
        RANK() OVER (ORDER BY total_casts DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title_id,
    tm.title,
    tm.production_year,
    tm.total_casts,
    tm.actor_names,
    STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title_id, tm.title, tm.production_year, tm.total_casts, tm.actor_names
ORDER BY 
    tm.rank;
