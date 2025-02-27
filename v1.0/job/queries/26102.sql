WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        a.id AS movie_id,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, COUNT(DISTINCT ak.name) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        a.title, a.production_year, a.id
),
TopRankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_id,
        actor_names,
        keyword_count 
    FROM 
        RankedMovies 
    WHERE 
        rank <= 5
)

SELECT 
    tr.movie_title,
    tr.production_year,
    tr.actor_names,
    tr.keyword_count,
    mt.info AS movie_info,
    ct.kind AS company_type
FROM 
    TopRankedMovies tr
LEFT JOIN 
    movie_info mt ON tr.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON tr.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
ORDER BY 
    tr.production_year DESC, 
    tr.keyword_count DESC;
