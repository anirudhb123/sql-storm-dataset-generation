WITH movie_keywords AS (
    SELECT 
        mk.movie_id, 
        array_agg(k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ak.name AS director,
        co.name AS company_name,
        mki.info AS additional_info
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND ci.movie_id = t.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_info mki ON t.id = mki.movie_id
    WHERE 
        ak.name IS NOT NULL AND co.name IS NOT NULL
),
keyword_statistics AS (
    SELECT 
        movie_id,
        COUNT(*) AS keyword_count
    FROM 
        movie_keywords
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.director,
    md.company_name,
    mk.keywords,
    kf.keyword_count
FROM 
    movie_details md
LEFT JOIN 
    movie_keywords mk ON md.movie_id = mk.movie_id
LEFT JOIN 
    keyword_statistics kf ON md.movie_id = kf.movie_id
ORDER BY 
    md.production_year DESC, md.title;
