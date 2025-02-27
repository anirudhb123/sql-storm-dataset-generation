WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name SEPARATOR ', ') AS actors,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name SEPARATOR ', ') AS companies,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT i.info ORDER BY i.info SEPARATOR ', ') AS info
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = t.id
    LEFT JOIN 
        info_type i ON i.id = mi.info_type_id
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actors,
        companies,
        keywords,
        info,
        DENSE_RANK() OVER (PARTITION BY production_year ORDER BY title) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_id,
    title,
    production_year,
    actors,
    companies,
    keywords,
    info,
    rank
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, rank;
