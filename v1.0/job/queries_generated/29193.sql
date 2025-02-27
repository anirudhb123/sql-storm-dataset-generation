WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT p.info) AS person_info
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_type AS c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        person_info AS p ON ak.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actors,
        keywords,
        company_type,
        person_info,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY COUNT(DISTINCT actors) DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    actors,
    keywords,
    company_type,
    person_info
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, 
    rank;
