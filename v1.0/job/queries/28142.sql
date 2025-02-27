
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT pi.info, ', ') AS person_info
    FROM 
        aka_title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type AS c ON mc.company_type_id = c.id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        person_info AS pi ON ci.person_id = pi.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.kind
), RankedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        company_type,
        aka_names,
        person_info,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS rank
    FROM 
        MovieDetails
)
SELECT 
    rank,
    movie_id,
    movie_title,
    production_year,
    movie_keyword,
    company_type,
    aka_names,
    person_info
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, rank;
