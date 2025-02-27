WITH movie_durations AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(cc.id) AS cast_count,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        t.id, t.title
),
ranked_movies AS (
    SELECT 
        movie_id,
        title,
        cast_count,
        keyword_count,
        company_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC, keyword_count DESC) AS rank
    FROM 
        movie_durations
),
top_movies AS (
    SELECT 
        rm.*,
        COALESCE(AVG(pi.info::float), 0) AS average_rating
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        person_info pi ON rm.movie_id = pi.person_id
    WHERE 
        rm.rank <= 10
    GROUP BY 
        rm.movie_id, rm.title, rm.cast_count, rm.keyword_count, rm.company_count
)
SELECT 
    tm.title,
    tm.cast_count,
    tm.keyword_count,
    tm.company_count,
    tm.average_rating
FROM 
    top_movies tm
LEFT JOIN 
    aka_name an ON tm.movie_id = an.person_id
WHERE 
    an.name IS NOT NULL
    AND (tm.average_rating > 5.0 OR tm.cast_count > 5)
ORDER BY 
    tm.rank;
