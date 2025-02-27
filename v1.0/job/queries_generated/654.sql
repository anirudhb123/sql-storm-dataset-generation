WITH MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_role_assignments
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        mt.production_year >= 2000 AND 
        (ct.kind IS NOT NULL OR mc.note IS NOT NULL)
    GROUP BY 
        mt.id, mt.title, mt.production_year, ct.kind
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_type,
        md.total_cast,
        md.avg_role_assignments,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordCounts kc ON md.movie_id = kc.movie_id
    WHERE 
        md.total_cast > 5 AND 
        md.avg_role_assignments > 0.5
)
SELECT 
    tm.title,
    tm.production_year,
    tm.company_type,
    tm.total_cast,
    tm.keyword_count
FROM 
    TopMovies tm
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = tm.movie_id AND 
              mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
    )
ORDER BY 
    tm.total_cast DESC, 
    tm.keyword_count ASC;
