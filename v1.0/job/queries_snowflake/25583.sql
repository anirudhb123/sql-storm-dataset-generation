
WITH MovieRankings AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title, 
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        movie_id, 
        movie_title,
        production_year,
        actor_count,
        aka_names,
        keywords,
        RANK() OVER (ORDER BY actor_count DESC) AS actor_rank
    FROM 
        MovieRankings
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.actor_count,
    rm.aka_names,
    rm.keywords,
    CASE 
        WHEN rm.actor_count > 10 THEN 'Highly Casted'
        WHEN rm.actor_count BETWEEN 5 AND 10 THEN 'Moderately Casted'
        ELSE 'Low Casted'
    END AS cast_category
FROM 
    RankedMovies rm
WHERE 
    rm.production_year BETWEEN 2000 AND 2023
ORDER BY 
    rm.actor_rank, rm.production_year DESC
LIMIT 50;
