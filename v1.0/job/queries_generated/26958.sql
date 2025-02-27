WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name ASC) AS aliases,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword ASC) AS keywords,
        GROUP_CONCAT(DISTINCT c.kind ORDER BY c.kind ASC) AS cast_types,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name ASC) AS production_companies
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (
            SELECT ci.person_id 
            FROM cast_info ci 
            WHERE ci.movie_id = t.movie_id
        )
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.movie_id
    LEFT JOIN 
        company_name co ON co.id = mc.company_id
    LEFT JOIN 
        comp_cast_type c ON c.id = mc.company_type_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        aliases,
        keywords,
        cast_types,
        production_companies,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS rn
    FROM 
        MovieDetails
)
SELECT 
    rn,
    movie_title,
    production_year,
    aliases,
    keywords,
    cast_types,
    production_companies
FROM 
    TopMovies
WHERE 
    rn <= 10
ORDER BY 
    production_year DESC;
