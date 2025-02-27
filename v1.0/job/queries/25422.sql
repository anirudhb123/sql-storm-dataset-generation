
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(*) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (
            SELECT 
                id 
            FROM 
                kind_type 
            WHERE 
                kind = 'movie'
        )
    GROUP BY 
        t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.movie_title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        mc.movie_id,
        c.id AS company_id,
        c.name AS company_name,
        ct.kind AS company_type,
        c.country_code
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year IN (SELECT production_year FROM TopRatedMovies)
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.company_type,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    COUNT(DISTINCT mk.keyword_id) AS total_keywords
FROM 
    MovieDetails md
LEFT JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
GROUP BY 
    md.title, md.production_year, md.company_name, md.company_type
ORDER BY 
    md.production_year DESC, total_cast DESC;
