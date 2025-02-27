WITH RankedMovies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS c ON a.person_id = c.person_id
    JOIN 
        aka_title AS t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS genres
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        aka_title AS m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
Companies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
)
SELECT 
    r.actor_name,
    r.movie_title,
    r.production_year,
    coalesce(g.genres, '{}') AS genres,
    COALESCE(c.company_name, 'Independent') AS company_name,
    COUNT(*) OVER (PARTITION BY r.production_year) AS total_movies,
    AVG(CASE WHEN c.company_type = 'Distributor' THEN 1 ELSE 0 END) OVER (PARTITION BY r.production_year) AS distributor_ratio
FROM 
    RankedMovies AS r
LEFT JOIN 
    MovieGenres AS g ON r.movie_title = (SELECT title FROM aka_title WHERE id = r.movie_title)
LEFT JOIN 
    Companies AS c ON r.movie_title = (SELECT title FROM aka_title WHERE id = c.movie_id)
WHERE 
    r.rank <= 10 AND
    r.production_year BETWEEN 2000 AND 2023
ORDER BY 
    r.production_year DESC, r.actor_name;
