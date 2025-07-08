
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

company_movie_data AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS total_cast_members
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON mc.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),

movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
    COALESCE(cmd.company_name, 'Unknown Company') AS company_name,
    COALESCE(cmd.company_type, 'N/A') AS company_type,
    COALESCE(cmd.total_cast_members, 0) AS total_cast_members,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN mk.keywords IS NOT NULL THEN 'Has Keywords'
        ELSE 'No Keywords'
    END AS keyword_status
FROM 
    ranked_movies rm
LEFT JOIN 
    company_movie_data cmd ON rm.movie_id = cmd.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title ASC;
