WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        movie_id
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        m.title, 
        m.production_year, 
        array_agg(DISTINCT k.keyword) AS keywords,
        array_agg(DISTINCT cn.name) AS companies
    FROM 
        TopMovies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = m.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        m.title, m.production_year, m.movie_id
)
SELECT 
    d.title, 
    d.production_year, 
    COALESCE(d.keywords, '{}') AS keywords,
    COALESCE(d.companies, '{}') AS companies,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = d.movie_id) AS cast_count,
    (SELECT STRING_AGG(DISTINCT CONCAT(pa.name, ' as ', r.role), ', ') 
     FROM cast_info ci 
     JOIN role_type r ON ci.role_id = r.id 
     JOIN aka_name pa ON ci.person_id = pa.person_id 
     WHERE ci.movie_id = d.movie_id) AS cast_details
FROM 
    MovieDetails d
ORDER BY 
    d.production_year DESC, 
    d.title ASC;
