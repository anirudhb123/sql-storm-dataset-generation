WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        COUNT(DISTINCT k.keyword) AS total_keywords,
        COALESCE(SUM(a_person.role_id IS NOT NULL::int), 0) AS total_cast_members
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info a_person ON cc.subject_id = a_person.person_id
    GROUP BY 
        m.id
), 
RankedByCast AS (
    SELECT
        movie_id,
        title,
        production_year,
        companies,
        total_companies,
        total_keywords,
        total_cast_members,
        RANK() OVER (ORDER BY total_cast_members DESC) AS cast_rank
    FROM 
        RankedMovies
)

SELECT 
    rb.title,
    rb.production_year,
    rb.companies,
    rb.total_companies,
    rb.total_keywords,
    rb.total_cast_members,
    rb.cast_rank
FROM 
    RankedByCast rb
WHERE 
    rb.total_keywords > 10
ORDER BY 
    rb.cast_rank, rb.production_year DESC
LIMIT 50;
