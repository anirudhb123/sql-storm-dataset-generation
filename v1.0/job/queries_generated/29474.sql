WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ka.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT ka.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT ci.kind, ', ') AS company_types
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON ci.movie_id = t.movie_id
    LEFT JOIN 
        aka_name AS ka ON ka.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies AS mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
), MovieRankings AS (
    SELECT
        *,
        RANK() OVER (ORDER BY num_cast_members DESC) AS cast_rank
    FROM 
        RankedMovies
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.num_cast_members,
    m.cast_names,
    m.keywords,
    m.company_types,
    m.cast_rank
FROM 
    MovieRankings AS m
WHERE 
    m.cast_rank <= 10
ORDER BY 
    m.cast_rank;
