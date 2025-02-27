
WITH ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ak.title, ', ') AS titles,
        STRING_AGG(DISTINCT CAST(ak.production_year AS TEXT), ', ') AS production_years
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title ak ON ci.movie_id = ak.movie_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.id, a.name
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
MovieKeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(ai.actor_names, 'No Actors') AS actor_names,
        COALESCE(mci.companies, 'No Companies') AS companies,
        COALESCE(mki.keywords, 'No Keywords') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        (SELECT 
            ci.movie_id, STRING_AGG(DISTINCT a.name, ', ') AS actor_names
         FROM 
            cast_info ci 
         JOIN 
            aka_name a ON ci.person_id = a.person_id 
         GROUP BY 
            ci.movie_id) ai ON mt.movie_id = ai.movie_id
    LEFT JOIN 
        MovieCompanyInfo mci ON mt.movie_id = mci.movie_id
    LEFT JOIN 
        MovieKeywordInfo mki ON mt.movie_id = mki.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_names,
    md.companies,
    md.keywords
FROM 
    MovieDetails md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
