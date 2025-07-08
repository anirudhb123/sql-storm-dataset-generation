WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        p.gender,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        name p ON ca.person_id = p.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.title, t.production_year, k.keyword, c.kind, p.gender
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        company_type,
        gender,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM 
        MovieDetails
)
SELECT 
    production_year,
    COUNT(*) AS total_movies,
    SUM(cast_count) AS total_cast_count,
    MAX(CASE WHEN gender = 'F' THEN cast_count ELSE 0 END) AS max_female_cast,
    MAX(CASE WHEN gender = 'M' THEN cast_count ELSE 0 END) AS max_male_cast
FROM 
    RankedMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
