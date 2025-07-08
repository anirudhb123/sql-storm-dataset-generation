
WITH MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        c.kind AS company_type,
        ARRAY_AGG(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT p.name ORDER BY p.name) AS cast_members
    FROM 
        aka_title t
    INNER JOIN movie_companies mc ON t.id = mc.movie_id
    INNER JOIN company_type c ON mc.company_type_id = c.id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN aka_name p ON cc.subject_id = p.id
    GROUP BY 
        t.title, t.production_year, c.kind
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        company_type,
        keywords,
        cast_members,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY title) AS movie_rank
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000
        AND company_type IS NOT NULL
        AND keywords IS NOT NULL
)

SELECT 
    f.title,
    f.production_year,
    f.company_type,
    f.keywords,
    f.cast_members
FROM 
    FilteredMovies f
WHERE 
    f.movie_rank <= 10
ORDER BY 
    f.production_year DESC, 
    f.title ASC;
