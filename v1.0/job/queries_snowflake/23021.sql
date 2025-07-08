
WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS movie_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
cast_info_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        LISTAGG(DISTINCT p.name, ', ') WITHIN GROUP (ORDER BY p.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    GROUP BY 
        ci.movie_id
),
genre_types AS (
    SELECT 
        m.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
company_involvement AS (
    SELECT 
        mc.movie_id,
        LISTAGG(c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS companies_involved
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
critical_insights AS (
    SELECT 
        cm.movie_id,
        AVG(CASE WHEN m.info_type_id IN (1, 2, 3) THEN 1 ELSE NULL END) AS avg_score,
        MIN(CASE WHEN m.info IS NULL THEN 1 ELSE 0 END) AS missing_info
    FROM 
        complete_cast cm
    LEFT JOIN 
        movie_info m ON cm.movie_id = m.movie_id
    GROUP BY 
        cm.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(cs.total_cast, 0) AS total_cast,
    COALESCE(cs.cast_names, 'No Cast') AS cast_names,
    COALESCE(gt.genres, 'No Genre') AS genres,
    COALESCE(ci.companies_involved, 'No Companies') AS companies_involved,
    COALESCE(critical.avg_score, 0) AS avg_score,
    CASE 
        WHEN critical.missing_info = 1 THEN 'Missing Info' 
        ELSE 'All Info Present' 
    END AS info_status
FROM 
    ranked_movies r
LEFT JOIN 
    cast_info_summary cs ON r.movie_id = cs.movie_id
LEFT JOIN 
    genre_types gt ON r.movie_id = gt.movie_id
LEFT JOIN 
    company_involvement ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    critical_insights critical ON critical.movie_id = r.movie_id
WHERE 
    r.movie_rank <= 5
ORDER BY 
    r.production_year DESC, r.title ASC;
