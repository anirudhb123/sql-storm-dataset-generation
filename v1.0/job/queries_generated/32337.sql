WITH RECURSIVE FullMovieInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        array_agg(DISTINCT c.name) AS cast_members,
        array_agg(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
MovieCompanyDetails AS (
    SELECT 
        m.movie_id,
        array_agg(DISTINCT cn.name) AS companies,
        array_agg(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
),
AggregatedMovieInfo AS (
    SELECT 
        f.title_id,
        f.title,
        f.production_year,
        f.cast_members,
        f.keywords,
        mcd.companies,
        mcd.company_types
    FROM 
        FullMovieInfo f
    LEFT JOIN 
        MovieCompanyDetails mcd ON f.title_id = mcd.movie_id
)

SELECT 
    ami.title,
    ami.production_year,
    COALESCE(ami.cast_members, '{}') AS cast_members,
    COALESCE(ami.keywords, '{}') AS keywords,
    COALESCE(ami.companies, '{}') AS companies,
    COALESCE(ami.company_types, '{}') AS company_types
FROM 
    AggregatedMovieInfo ami
WHERE 
    ami.production_year >= 2000
    AND EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = ami.title_id
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Box Office')
        AND mi.info IS NOT NULL
    )
ORDER BY 
    ami.production_year DESC, ami.title;
