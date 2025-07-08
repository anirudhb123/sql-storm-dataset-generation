
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        k.keyword,
        n.name AS actor_name,
        c.name AS company_name
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        rm.rank <= 10
)
SELECT 
    pm.movie_id,
    pm.title,
    pm.production_year,
    pm.cast_count,
    LISTAGG(DISTINCT pm.keyword, ', ') WITHIN GROUP (ORDER BY pm.keyword) AS keywords,
    LISTAGG(DISTINCT pm.actor_name, ', ') WITHIN GROUP (ORDER BY pm.actor_name) AS actors,
    LISTAGG(DISTINCT pm.company_name, ', ') WITHIN GROUP (ORDER BY pm.company_name) AS companies
FROM 
    PopularMovies pm
GROUP BY 
    pm.movie_id, pm.title, pm.production_year, pm.cast_count
ORDER BY 
    pm.cast_count DESC;
