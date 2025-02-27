WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COALESCE(cast_aka.name, name.name) AS person_name,
        ct.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name cast_aka ON c.person_id = cast_aka.person_id
    LEFT JOIN 
        name ON cast_aka.person_id = name.imdb_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
    GROUP BY 
        t.title, t.production_year, person_name, company_type
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        person_name,
        company_type,
        keywords,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    person_name,
    company_type,
    keywords,
    cast_count
FROM 
    RankedMovies
WHERE 
    rank <= 5
ORDER BY 
    production_year, cast_count DESC;
