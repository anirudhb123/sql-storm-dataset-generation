WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        y.production_year AS year,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.name AS company_name,
        ct.kind AS company_type_name
    FROM 
        title m
    JOIN 
        aka_title y ON m.id = y.movie_id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        y.production_year >= 2000 
    GROUP BY 
        m.id, m.title, y.production_year, c.name, ct.kind
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN year < 2010 THEN 'Before 2010' 
            ELSE '2010 and After' 
        END AS period
    FROM 
        MovieDetails
)

SELECT 
    period,
    COUNT(DISTINCT movie_id) AS movie_count,
    STRING_AGG(DISTINCT movie_title, ', ') AS movies,
    STRING_AGG(DISTINCT company_name, ', ') AS companies,
    STRING_AGG(DISTINCT company_type_name, ', ') AS company_types,
    STRING_AGG(DISTINCT actors, ', ') AS actors_list,
    STRING_AGG(DISTINCT keywords, ', ') AS keywords_list
FROM 
    FilteredMovies
GROUP BY 
    period
ORDER BY 
    period;
