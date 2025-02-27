WITH RECURSIVE t AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT ai.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        MAX(i.info) FILTER (WHERE it.info = 'summary') AS movie_summary,
        MAX(k.keyword) AS movie_keywords,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY COUNT(ai.person_id) DESC) AS rank
    FROM 
        complete_cast cc
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        movie_info i ON c.movie_id = i.movie_id
    JOIN 
        info_type it ON i.info_type_id = it.id
    JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        i.note IS NULL
    GROUP BY 
        c.movie_id
), ranked_movies AS (
    SELECT 
        t.*,
        COUNT(*) OVER () AS total_movies
    FROM 
        t
    WHERE 
        actor_count > 1
), outer_query AS (
    SELECT 
        rm.movie_id,
        rm.actors,
        rm.movie_summary,
        rm.movie_keywords,
        rm.rank,
        COALESCE(m.title, 'Unknown Title') AS title
    FROM 
        ranked_movies rm
    LEFT JOIN 
        aka_title m ON rm.movie_id = m.movie_id
)
SELECT 
    om.title,
    om.actors,
    om.movie_summary,
    om.movie_keywords,
    om.rank,
    om.total_movies,
    CASE 
        WHEN om.rank <= 10 THEN 'Top Movie'
        ELSE 'Regular Movie'
    END AS movie_category
FROM 
    outer_query om
WHERE 
    om.movie_keywords IS NOT NULL
ORDER BY 
    om.rank;
