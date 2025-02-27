
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names,
        COALESCE(AVG(CAST(mi.info AS FLOAT)), 0) AS average_rating,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT ci.person_role_id) AS unique_roles
    FROM 
        aka_title AS t
    LEFT JOIN 
        aka_name AS ak ON t.id = ak.person_id
    LEFT JOIN 
        cast_info AS ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        name AS p ON ci.person_id = p.imdb_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info AS mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        t.id, t.title
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        aka_names,
        cast_names,
        average_rating,
        keyword_count,
        company_count,
        unique_roles,
        RANK() OVER (ORDER BY average_rating DESC, keyword_count DESC, company_count DESC) AS ranking
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    aka_names,
    cast_names,
    average_rating,
    keyword_count,
    company_count,
    unique_roles,
    ranking
FROM 
    TopMovies
WHERE 
    ranking <= 10
ORDER BY 
    ranking;
