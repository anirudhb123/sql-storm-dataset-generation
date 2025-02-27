WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year >= 2000
),
TopMovies AS (
    SELECT 
        m.title, 
        COUNT(c.person_id) AS cast_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    WHERE 
        m.rn <= 5
    GROUP BY 
        m.title
),
MovieDetails AS (
    SELECT 
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE(cn.name, 'Unknown') AS company_name
    FROM 
        TopMovies t
    LEFT JOIN 
        movie_keyword mk ON t.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.title, t.production_year, cn.name
)
SELECT 
    md.title, 
    md.production_year, 
    md.keywords,
    p.info AS person_info
FROM 
    MovieDetails md
LEFT JOIN 
    person_info p ON p.person_id = (
        SELECT person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = md.title 
        ORDER BY ci.nr_order 
        LIMIT 1
    )
WHERE 
    md.company_name IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title;
