
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
company_details AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies,
        MAX(ct.kind) AS company_type
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
ranked_movies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.cast_count,
        cd.companies,
        cd.company_type,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.cast_count DESC) AS rank
    FROM 
        movie_details md
    LEFT JOIN 
        company_details cd ON md.movie_id = cd.movie_id
),
release_summary AS (
    SELECT 
        production_year,
        SUM(cast_count) AS total_cast_count,
        COUNT(movie_id) AS total_movies,
        COUNT(DISTINCT keyword) AS distinct_keywords
    FROM 
        ranked_movies
    GROUP BY 
        production_year
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword,
    rm.cast_count,
    rm.companies,
    COALESCE(rm.company_type, 'Independent') AS company_category,
    rs.total_cast_count,
    rs.total_movies,
    rs.distinct_keywords,
    (rs.total_cast_count * 1.0 / NULLIF(rs.total_movies, 0)) AS avg_cast_per_movie
FROM 
    ranked_movies rm
JOIN 
    release_summary rs ON rm.production_year = rs.production_year
WHERE 
    rm.rank <= 5 OR 
    (rm.rank IS NULL AND rm.cast_count > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
