WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id
), 
KeywordAggregation AS (
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
MovieCompanies AS (
    SELECT
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.num_actors,
        md.actor_names,
        COALESCE(ka.keywords, 'No Keywords') AS keywords,
        COALESCE(mc.companies, 'No Companies') AS companies,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.num_actors DESC) AS rank
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordAggregation ka ON md.movie_id = ka.movie_id
    LEFT JOIN 
        MovieCompanies mc ON md.movie_id = mc.movie_id
)

SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.num_actors,
    rm.actor_names,
    rm.keywords,
    rm.companies
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.num_actors DESC;
