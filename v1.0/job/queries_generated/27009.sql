WITH MovieDetails AS (
    SELECT 
        t.title AS MovieTitle,
        t.production_year AS ReleaseYear,
        GROUP_CONCAT(DISTINCT ak.name SEPARATOR ', ') AS Aliases,
        GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS Keywords,
        GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS Companies,
        COUNT(DISTINCT ca.person_id) AS CastCount
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name ak ON ak.person_id = (SELECT person_id FROM cast_info c WHERE c.movie_id = t.movie_id LIMIT 1)
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name c ON c.id = mc.company_id
    LEFT JOIN 
        cast_info ca ON ca.movie_id = t.id
    GROUP BY 
        t.id
),
TopMovies AS (
    SELECT 
        MovieTitle,
        ReleaseYear,
        Aliases,
        Keywords,
        Companies,
        CastCount,
        ROW_NUMBER() OVER (ORDER BY ReleaseYear DESC, CastCount DESC) AS Rank
    FROM 
        MovieDetails
)
SELECT 
    *
FROM 
    TopMovies
WHERE 
    Rank <= 10;
