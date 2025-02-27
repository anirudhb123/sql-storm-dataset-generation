WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
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
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY actor_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_count,
    tm.aka_names,
    ci.note AS cast_note,
    cn.country_code,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.title = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON tm.title = mi.movie_id
LEFT JOIN 
    company_name cn ON tm.title = cn.id
LEFT JOIN 
    cast_info ci ON tm.actor_count = ci.nr_order
WHERE 
    tm.rank <= 10
GROUP BY 
    tm.title, tm.production_year, tm.actor_count, tm.aka_names, ci.note, cn.country_code
ORDER BY 
    tm.actor_count DESC;
