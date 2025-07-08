
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        ROW_NUMBER() OVER (ORDER BY rm.actor_count DESC) AS rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.actor_count > 5
)
SELECT 
    tr.movie_id,
    tr.title,
    tr.production_year,
    tr.actor_count,
    LISTAGG(DISTINCT ckt.keyword, ', ') AS keywords
FROM 
    TopRatedMovies tr
LEFT JOIN 
    movie_keyword mk ON tr.movie_id = mk.movie_id
LEFT JOIN 
    keyword ckt ON mk.keyword_id = ckt.id
WHERE 
    tr.rank <= 10
GROUP BY 
    tr.movie_id, tr.title, tr.production_year, tr.actor_count
ORDER BY 
    tr.actor_count DESC;
