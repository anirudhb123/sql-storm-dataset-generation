
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t 
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        r.rank
    FROM 
        RankedMovies r
    LEFT JOIN 
        complete_cast cc ON r.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_companies mc ON r.movie_id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON r.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        r.movie_id,
        r.title,
        r.production_year,
        r.rank
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.companies,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.rank <= 5
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
