WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        kt.kind AS keyword_type,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS co_actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.id
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    AND 
        c.country_code = 'USA'
    GROUP BY 
        t.id, t.title, t.production_year, c.name, kt.kind
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        company_name,
        actor_count,
        co_actors,
        keywords,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, production_year DESC) AS movie_rank
    FROM 
        MovieDetails
)
SELECT 
    movie_rank,
    movie_title,
    production_year,
    company_name,
    actor_count,
    co_actors,
    keywords
FROM 
    RankedMovies
WHERE 
    movie_rank <= 10
ORDER BY 
    movie_rank;
