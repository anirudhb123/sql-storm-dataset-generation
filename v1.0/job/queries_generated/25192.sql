WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_in_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        c.name AS company_name,
        ct.kind AS company_type,
        ARRAY_AGG(DISTINCT p.name) AS cast_members
    FROM 
        RankedMovies rm
    JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        person_info pi ON ci.person_id = pi.person_id
    JOIN 
        name p ON pi.person_id = p.imdb_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, c.name, ct.kind
),
FinalResults AS (
    SELECT 
        md.title,
        md.production_year,
        md.company_name,
        md.company_type,
        COUNT(md.cast_members) AS number_of_cast_members
    FROM 
        MovieDetails md
    WHERE 
        md.rank_in_year <= 5
    GROUP BY 
        md.title, md.production_year, md.company_name, md.company_type
)
SELECT 
    *,
    CONCAT('Movie: ', title, ' | Year: ', production_year, ' | Company: ', company_name, ' | Type: ', company_type, ' | Cast Count: ', number_of_cast_members) AS benchmark_info
FROM 
    FinalResults
ORDER BY 
    production_year DESC, number_of_cast_members DESC;
