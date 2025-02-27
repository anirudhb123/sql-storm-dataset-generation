WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS companies
    FROM
        aka_title AS t
    JOIN
        cast_info AS ci ON t.id = ci.movie_id
    JOIN
        aka_name AS a ON ci.person_id = a.person_id
    LEFT JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN
        company_name AS c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000 
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actors,
        keywords,
        companies,
        RANK() OVER (PARTITION BY production_year ORDER BY COUNT(DISTINCT actors) DESC) AS rank
    FROM
        MovieDetails
    GROUP BY 
        movie_id, title, production_year, actors, keywords, companies
)
SELECT 
    R.movie_id,
    R.title,
    R.production_year,
    R.actors,
    R.keywords,
    R.companies,
    R.rank
FROM 
    RankedMovies AS R
WHERE 
    R.rank <= 5
ORDER BY 
    R.production_year DESC, 
    R.rank;
