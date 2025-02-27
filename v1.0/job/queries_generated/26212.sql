WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(ci.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_aka_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON ci.movie_id = a.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rt.role AS leading_role,
        COUNT(mc.company_id) AS production_companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS movie_keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = rm.movie_id
    LEFT JOIN 
        role_type rt ON rt.id = cc.status_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = rm.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, rt.role
),
FinalOutput AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.leading_role,
        md.production_companies,
        md.movie_keywords,
        rm.num_cast_members,
        rm.all_aka_names
    FROM 
        MovieDetails md
    JOIN 
        RankedMovies rm ON md.movie_id = rm.movie_id
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    leading_role,
    production_companies,
    num_cast_members,
    movie_keywords,
    all_aka_names
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, 
    num_cast_members DESC;
