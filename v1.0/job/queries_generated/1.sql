WITH MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors
    FROM 
        aka_title AS t
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id, 
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
), 
MovieRatings AS (
    SELECT 
        mi.movie_id, 
        MAX(CASE WHEN it.info = 'rating' THEN mi.info END) AS max_rating,
        MAX(CASE WHEN it.info = 'votes' THEN mi.info END) AS total_votes
    FROM 
        movie_info AS mi
    JOIN 
        info_type AS it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
) 
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.actors,
    ci.company_name,
    ci.company_type,
    mr.max_rating,
    mr.total_votes
FROM 
    MovieDetails AS md
LEFT JOIN 
    CompanyInfo AS ci ON md.id = ci.movie_id
LEFT JOIN 
    MovieRatings AS mr ON md.id = mr.movie_id
WHERE 
    (md.production_year >= 2000 OR md.cast_count > 5)
    AND (mr.max_rating IS NOT NULL OR md.cast_count > 10)
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;
