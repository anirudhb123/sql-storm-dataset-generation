
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT c.role_id::TEXT, ', ') WITHIN GROUP (ORDER BY c.role_id) AS role_ids,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS movie_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        k.keyword LIKE '%action%'  
        AND t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        aka_names,
        role_ids,
        movie_rank
    FROM 
        RankedMovies
    WHERE 
        movie_rank <= 5
)
SELECT 
    movie_title,
    production_year,
    aka_names,
    role_ids
FROM 
    TopMovies
ORDER BY 
    production_year DESC, movie_title;
