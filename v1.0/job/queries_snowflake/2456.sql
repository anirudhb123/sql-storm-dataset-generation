
WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        LISTAGG(c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cd.company_count, 0) AS number_of_companies,
    COALESCE(cd.company_names, 'None') AS companies,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = rm.movie_id AND mi.info_type_id = 1) AS review_count,
    CASE 
        WHEN rm.rank <= 5 THEN 'Top 5'
        WHEN rm.rank BETWEEN 6 AND 15 THEN 'Top 15'
        ELSE 'Other'
    END AS ranking_group
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
WHERE 
    rm.production_year >= 2000 
    AND (rm.title ILIKE '%star%' OR rm.title ILIKE '%night%')
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cd.company_count, cd.company_names, mk.keywords, rm.rank
ORDER BY 
    rm.production_year DESC, total_actors DESC;
