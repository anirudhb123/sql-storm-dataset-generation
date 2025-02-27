WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        COUNT(ci.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
    ORDER BY 
        cast_count DESC
    LIMIT 10
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        ct.kind AS company_type,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_title = (
            SELECT title 
            FROM title 
            WHERE id = mc.movie_id
        )
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        rm.movie_title, rm.production_year, rm.cast_count, ct.kind
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    company_type,
    companies
FROM 
    MovieDetails
ORDER BY 
    production_year DESC, cast_count DESC;
