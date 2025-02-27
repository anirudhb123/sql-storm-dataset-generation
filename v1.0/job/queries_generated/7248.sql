WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
), MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(k.keyword, 'No Keywords') AS keywords,
        ct.kind AS company_type,
        cn.name AS company_name,
        pi.info AS person_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        person_info pi ON EXISTS (
            SELECT 1 FROM cast_info ci 
            WHERE ci.movie_id = rm.movie_id 
            AND ci.person_id = pi.person_id
        )
    WHERE 
        rm.rank_by_cast <= 5  -- limiting to top 5 ranked movies by cast
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.keywords, ', ') AS keyword_list,
    STRING_AGG(DISTINCT md.company_name || ' (' || md.company_type || ')', ', ') AS company_details,
    STRING_AGG(DISTINCT md.person_info, ', ') AS relevant_person_info
FROM 
    MovieDetails md
GROUP BY 
    md.movie_id, md.title, md.production_year
ORDER BY 
    md.production_year DESC, md.movie_id;
