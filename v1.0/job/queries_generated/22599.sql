WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id, 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rank_within_year
    FROM 
        aka_title at
    INNER JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%') 
        OR at.title LIKE '%adventure%'
), 

CastDetails AS (
    SELECT 
        ci.movie_id, 
        ci.person_id, 
        cn.name AS character_name, 
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY cn.name) AS character_rank
    FROM 
        cast_info ci
    LEFT JOIN 
        char_name cn ON ci.person_id = cn.imdb_id
    WHERE 
        ci.note IS NULL
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL AND cn.country_code <> ''
    GROUP BY 
        mc.movie_id
),

MovieInfo AS (
    SELECT 
        mi.movie_id, 
        MAX(CASE WHEN it.info = 'vote_average' THEN mi.info END) AS average_rating,
        MAX(CASE WHEN it.info = 'budget' THEN mi.info END) AS budget
    FROM 
        movie_info mi
    INNER JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
), 

FinalResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        cd.character_name,
        cd.character_rank,
        com.company_names,
        mv.average_rating,
        mv.budget,
        COALESCE(mv.budget::int, 0) / NULLIF(mv.average_rating::float, 0) AS budget_per_rating
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.aka_id = cd.movie_id
    LEFT JOIN 
        CompanyDetails com ON rm.aka_id = com.movie_id
    LEFT JOIN 
        MovieInfo mv ON rm.aka_id = mv.movie_id
    WHERE 
        rm.rank_within_year <= 3
)

SELECT 
    title,
    production_year,
    STRING_AGG(DISTINCT character_name, ', ') AS character_names,
    company_names,
    average_rating,
    budget,
    budget_per_rating
FROM 
    FinalResults
GROUP BY 
    title, production_year, company_names, average_rating, budget, budget_per_rating
ORDER BY 
    production_year DESC, average_rating DESC;

