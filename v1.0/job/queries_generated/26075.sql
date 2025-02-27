WITH MovieData AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        c.kind AS company_type,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title, t.production_year, ak.name, c.kind
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        company_type,
        keyword_count,
        keyword_list,
        RANK() OVER (PARTITION BY production_year ORDER BY keyword_count DESC) AS rank
    FROM 
        MovieData
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    company_type,
    keyword_count,
    keyword_list
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, rank;
