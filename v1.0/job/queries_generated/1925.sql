WITH ranked_movies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS num_cast_members,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
movies_with_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
movies_with_info AS (
    SELECT 
        m.title,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(string_agg(DISTINCT mi.info, '; '), 'No Info') AS additional_info
    FROM 
        movies_with_keywords mk
    LEFT JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        mk.title, mk.keywords
),
final_output AS (
    SELECT 
        mw.title,
        mw.keywords,
        mw.additional_info,
        rm.num_cast_members
    FROM 
        movies_with_info mw
    JOIN 
        ranked_movies rm ON mw.title = rm.title
    WHERE 
        rm.rank = 1 AND rm.num_cast_members > 1
)
SELECT 
    fo.title,
    fo.keywords,
    fo.additional_info,
    fo.num_cast_members
FROM 
    final_output fo
ORDER BY 
    fo.num_cast_members DESC;
