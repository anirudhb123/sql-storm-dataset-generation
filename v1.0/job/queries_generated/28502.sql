WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies
    FROM 
        aka_title t
    LEFT JOIN
        aka_name ak ON ak.person_id = t.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        keywords,
        companies,
        RANK() OVER (PARTITION BY production_year ORDER BY COUNT(aka_names) DESC) AS rank
    FROM 
        MovieDetails
    GROUP BY 
        movie_id, title, production_year, aka_names, keywords, companies
)

SELECT 
    rank,
    title,
    production_year,
    aka_names,
    keywords,
    companies
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, rank;
This SQL query benchmarks string processing across multiple tables and gathers movie details, including alternate names, keywords, and associated companies. The results are ranked with the top five titles for each production year starting from 2000.
