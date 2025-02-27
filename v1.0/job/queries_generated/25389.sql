WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT cname.name ORDER BY cname.name) AS companies,
        GROUP_CONCAT(DISTINCT person.name ORDER BY person.name) AS cast_members
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cname ON mc.company_id = cname.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name person ON c.person_id = person.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
LongTitles AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        movie_keyword,
        companies,
        cast_members,
        LENGTH(movie_title) AS title_length
    FROM 
        MovieDetails
    WHERE 
        LENGTH(movie_title) > 20
),
FinalResults AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        companies,
        cast_members
    FROM 
        LongTitles 
    WHERE 
        movie_keyword IS NOT NULL
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    companies,
    cast_members
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    title_length DESC;
