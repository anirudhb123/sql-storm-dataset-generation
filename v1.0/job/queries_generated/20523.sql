WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
        COALESCE(pi.info, 'No Info') AS person_info
    FROM 
        RankedMovies rm
    LEFT JOIN (
        SELECT 
            movie_id,
            STRING_AGG(keyword, ', ') AS keyword_list
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY
            movie_id
    ) mk ON rm.movie_id = mk.movie_id
    LEFT JOIN (
        SELECT 
            p.person_id,
            STRING_AGG(pi.info, '; ') AS info
        FROM 
            person_info pi
        JOIN 
            aka_name p ON pi.person_id = p.person_id
        WHERE 
            pi.info IS NOT NULL 
        GROUP BY 
            p.person_id
    ) pi ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = pi.person_id)
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.person_info,
    ct.kind AS company_type,
    COUNT(m.id) AS company_count
FROM 
    MovieDetails md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    (SELECT DISTINCT movie_id FROM complete_cast WHERE status_id IS NOT NULL) cc ON md.movie_id = cc.movie_id
WHERE 
    md.rank_by_cast = 1 OR md.production_year BETWEEN 2000 AND 2023
GROUP BY 
    md.title, md.production_year, md.keywords, md.person_info, ct.kind
HAVING 
    COUNT(m.id) >= 1 AND NOT EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = md.movie_id AND mi.info_type_id IS NULL)
ORDER BY 
    md.production_year DESC, company_count DESC;
