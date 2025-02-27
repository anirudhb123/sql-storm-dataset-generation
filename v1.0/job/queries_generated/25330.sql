WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies_count,
        COUNT(DISTINCT mk.keyword_id) AS keywords_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
), MovieSummaries AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.production_companies_count,
        rm.keywords_count,
        COALESCE(ARRAY_AGG(DISTINCT cn.name ORDER BY cn.name), '{}') AS company_names,
        COALESCE(ARRAY_AGG(DISTINCT kw.keyword ORDER BY kw.keyword), '{}') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        rm.rank <= 5 -- Top 5 movies per production year
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.production_companies_count, rm.keywords_count
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.production_companies_count,
    m.keywords_count,
    string_agg(DISTINCT c.name, ', ') AS cast_names,
    string_agg(DISTINCT kw.keyword, ', ') AS keywords
FROM 
    MovieSummaries m
LEFT JOIN 
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    aka_name an ON cc.subject_id = an.person_id
LEFT JOIN 
    cast_info ci ON an.id = ci.person_id
LEFT JOIN 
    role_type rt ON ci.person_role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    name n ON an.person_id = n.imdb_id
GROUP BY 
    m.movie_id, m.title, m.production_year, m.production_companies_count, m.keywords_count
ORDER BY 
    m.production_year DESC, m.keywords_count DESC;
