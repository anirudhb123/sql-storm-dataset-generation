WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        COALESCE(NULLIF(mk.keyword, ''), 'No Keyword') AS keyword,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = a.id
    LEFT JOIN 
        cast_info c ON c.movie_id = a.id
    GROUP BY 
        a.id, a.title, a.production_year, mk.keyword
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        p.gender,
        ROW_NUMBER() OVER (PARTITION BY p.gender ORDER BY p.name) AS gender_rank
    FROM 
        name p
    WHERE 
        p.gender IS NOT NULL
),
MovieCompany AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keyword,
    md.cast_count,
    COALESCE(mc.company_count, 0) AS company_count,
    pd.name,
    pd.gender,
    pd.gender_rank
FROM 
    MovieDetails md
LEFT JOIN 
    MovieCompany mc ON mc.movie_id = md.movie_id
LEFT JOIN 
    PersonDetails pd ON MD.movie_id IN (
        SELECT DISTINCT 
            cc.movie_id 
        FROM 
            complete_cast cc 
        WHERE 
            cc.person_id = pd.person_id
    )
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
