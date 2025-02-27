WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL 
        AND at.title IS NOT NULL
),
movie_with_keywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        ranked_movies rm
    LEFT JOIN movie_keyword mk ON mk.movie_id = rm.movie_id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
movies_with_cast AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        COALESCE(
            STRING_AGG(DISTINCT cn.name, ', '),
            'No cast information'
        ) AS cast_list
    FROM 
        movie_with_keywords mwk
    LEFT JOIN cast_info ci ON ci.movie_id = mwk.movie_id
    LEFT JOIN aka_name cn ON cn.person_id = ci.person_id
    GROUP BY 
        mwk.movie_id, mwk.title, mwk.production_year
),
movies_info AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        COALESCE(
            mi.info,
            'No additional info'
        ) AS additional_info
    FROM 
        movies_with_cast mwk
    LEFT JOIN movie_info mi ON mi.movie_id = mwk.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
),
final_output AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keywords,
        cast_list,
        additional_info
    FROM 
        movies_info
    JOIN (
        SELECT 
            DISTINCT movie_id
        FROM 
            movie_companies
        WHERE 
            company_type_id IN (SELECT id FROM company_type WHERE kind = 'Production')
    ) mc ON mc.movie_id = movies_info.movie_id
)
SELECT 
    fo.movie_id,
    fo.title,
    fo.production_year,
    fo.keywords,
    fo.cast_list,
    fo.additional_info,
    CASE 
        WHEN production_year < 2000 THEN 'Classic'
        WHEN production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era_category,
    LEAD(fo.title) OVER (ORDER BY fo.production_year) AS next_movie_title
FROM 
    final_output fo
ORDER BY 
    fo.production_year DESC, 
    fo.title;

