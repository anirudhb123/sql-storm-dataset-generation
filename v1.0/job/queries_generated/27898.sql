WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        t.kind AS title_kind,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rank_in_year
    FROM 
        aka_title m
    JOIN 
        kind_type t ON m.kind_id = t.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.title_kind,
        c.name AS company_name,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        rm.rank_in_year <= 5
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rm.title_kind, c.name, ct.kind
),
PersonDetails AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')') ORDER BY a.name) AS cast_list
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.title_kind,
    md.company_name,
    md.company_type,
    md.keywords,
    pd.cast_list
FROM 
    MovieDetails md
LEFT JOIN 
    PersonDetails pd ON md.movie_id = pd.movie_id
ORDER BY 
    md.production_year DESC, md.movie_title;
